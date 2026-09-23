import ARKit
import Foundation
import Observation
import RealityKit
import TwinfoldCore
import TwinfoldSpatial

/// One of the two demo wallets from fixtures/demo/wallets.json. Hardcoded
/// here (not loaded from the fixture bundle) to avoid exposing
/// wallets.json through TwinfoldCore's public API. Keep in sync with the
/// JSON file by hand per docs/architecture.md section 5 (core-contract
/// skill).
struct DemoWallet: Identifiable, Hashable {
    let id: String // wallet address
    let label: String

    static let ownerA = DemoWallet(id: "DEMOwalletA1111111111111111111111111111111", label: "Owner A (demo)")
    static let ownerB = DemoWallet(id: "DEMOwalletB2222222222222222222222222222222", label: "Owner B (demo)")
    static let all: [DemoWallet] = [ownerA, ownerB]

    static func label(forWallet wallet: String) -> String {
        all.first(where: { $0.id == wallet })?.label ?? wallet
    }
}

enum TransferState: Sendable, Equatable {
    case idle
    case pending
    case confirmed
    case failed
}

/// Shown after a transfer confirms, offering a shortcut to switch to the
/// receiving wallet so the Appear can be observed immediately.
struct TransferToast: Identifiable {
    let id = UUID()
    let assetTitle: String
    let destinationWallet: String
    var destinationLabel: String { DemoWallet.label(forWallet: destinationWallet) }
}

/// Everything materialized in the scene for one placed asset. Present only
/// while that asset is both placed (has a `PlacementCoord`) and owned by
/// `activeWallet` — `syncEntities()` adds/removes these as ownership or
/// wallet changes.
private struct LiveEntity {
    var anchor: AnchorEntity
    var cardEntity: Entity
    var provenanceColumn: Entity?
    var twinFootprint: (width: Float, height: Float)?
}

/// Session-only placement (world transform + how it was placed) for one
/// asset. Kept independently of `LiveEntity`/wallet: placement is a
/// property of the room, not of who currently owns the asset, so a
/// transferred asset reappears at the same spot once its new owner's
/// wallet is active.
private struct PlacementCoord {
    var transform: simd_float4x4
    var isWallPlacement: Bool
    var isFloorPlacement: Bool
    var wallRight: SIMD3<Float>?
    var wallUp: SIMD3<Float>?
    /// Wall: the card's real-world height (for top-edge snapping). Floor
    /// twin: the settled footprint height. Unused for an air placement.
    var footprintHeight: Float
}

/// Owns placement, selection, holding-preview and simulated-transfer state
/// for every asset in "My Room" (multiple assets at once, replacing the
/// old one-asset-per-screen `ARSceneController`). `ARContainerView` drives
/// this from ARKit tap/pan/per-frame events; this type only touches
/// RealityKit entities, the `TwinfoldSpatial` factories, and
/// `ARWorldTrackingConfiguration.isSupported` for the simulator fallback.
@MainActor
@Observable
final class RoomController {
    let provider: any AssetProvider
    let isARSupported = ARWorldTrackingConfiguration.isSupported

    weak var arView: ARView?

    private(set) var activeWallet: DemoWallet = .ownerA
    /// Assets `provider.getAssets(activeWallet)` currently returns. The
    /// tray lists these; only these (intersected with placement) ever get
    /// a live entity in the scene.
    private(set) var ownedAssets: [TwinfoldAsset] = []
    private(set) var loadErrorMessage: String?

    private(set) var holdingAssetId: String?
    private(set) var movingAssetId: String?
    private(set) var selectedAssetId: String?
    private(set) var transferStates: [String: TransferState] = [:]
    private(set) var toast: TransferToast?

    private var placementCoords: [String: PlacementCoord] = [:]
    private var liveEntities: [String: LiveEntity] = [:]

    private var previewAnchor: AnchorEntity?
    private var pendingPreviewTransform: simd_float4x4?
    private var pendingPreviewIsWall = false
    private var pendingPreviewWallBasis: (right: SIMD3<Float>, up: SIMD3<Float>)?
    private var pendingPreviewCardHeight: Float = 0

    private static let placementDistance: Float = 0.4
    private static let wallDragSensitivity: Float = 0.0015
    /// Top-edge height difference (meters) below which a newly-placed wall
    /// card snaps flush with an already-placed one.
    private static let wallSnapTolerance: Float = 0.03

    init(provider: any AssetProvider) {
        self.provider = provider
    }

    // MARK: - Wallet / ownership

    var placedCount: Int { placementCoords.count }
    var unplacedCount: Int { ownedAssets.filter { placementCoords[$0.id] == nil }.count }

    func isPlaced(_ assetId: String) -> Bool { placementCoords[assetId] != nil }
    func transferState(for assetId: String) -> TransferState { transferStates[assetId] ?? .idle }

    func start() async {
        await loadOwnedAssets()
    }

    func switchWallet(to wallet: DemoWallet) {
        guard wallet.id != activeWallet.id else { return }
        activeWallet = wallet
        selectedAssetId = nil
        holdingAssetId = nil
        cancelHolding()
        Task { await loadOwnedAssets() }
    }

    private func loadOwnedAssets() async {
        if let mock = provider as? MockAssetProvider {
            await mock.connect(wallet: activeWallet.id)
        }
        do {
            ownedAssets = try await provider.getAssets(wallet: activeWallet.id)
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = "資産を読み込めませんでした: \(error)"
        }
        syncEntities()
    }

    /// Adds/removes scene entities so only assets that are both placed
    /// (`placementCoords`) and owned by `activeWallet` (`ownedAssets`) are
    /// visible — the Appear/Disappear mechanism for both wallet switches
    /// and transfer confirmation.
    private func syncEntities() {
        let ownedIds = Set(ownedAssets.map(\.id))

        for (assetId, live) in liveEntities where !ownedIds.contains(assetId) {
            arView?.scene.removeAnchor(live.anchor)
            liveEntities[assetId] = nil
            if selectedAssetId == assetId { selectedAssetId = nil }
            if movingAssetId == assetId { movingAssetId = nil }
        }

        for asset in ownedAssets {
            guard liveEntities[asset.id] == nil, let coord = placementCoords[asset.id] else { continue }
            materialize(assetId: asset.id, asset: asset, transform: coord.transform, isWall: coord.isWallPlacement, wallBasis: coord.wallRight.map { ($0, coord.wallUp ?? SIMD3<Float>(0, 1, 0)) })
        }
    }

    // MARK: - Tray

    /// Tapping a tray thumbnail: an unplaced asset starts a holding
    /// preview; an already-placed one just selects it (same as tapping its
    /// entity in the scene).
    func trayTap(assetId: String) {
        if placementCoords[assetId] != nil {
            select(assetId)
        } else {
            startHolding(assetId: assetId)
        }
    }

    // MARK: - Holding (placement preview)

    func startHolding(assetId: String) {
        guard let asset = ownedAssets.first(where: { $0.id == assetId }), let arView else { return }
        removePreviewOnly()
        selectedAssetId = nil
        movingAssetId = nil
        holdingAssetId = assetId
        pendingPreviewTransform = nil

        let entity = AssetRepresentationEntity.make(asset: asset)
        // Reuses the pending look (semi-transparent) as the placement
        // preview.
        AssetCardEntity.apply(state: .pending, to: entity)
        let anchor = AnchorEntity(world: matrix_identity_float4x4)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        previewAnchor = anchor
    }

    func cancelHolding() {
        removePreviewOnly()
        holdingAssetId = nil
        pendingPreviewTransform = nil
    }

    /// Called every frame (via `ARContainerView`'s scene-update
    /// subscription) while holding, so the preview follows the raycast
    /// from the center of the screen.
    func updateHoldingPreview() {
        guard let holdingAssetId,
              let arView,
              let asset = ownedAssets.first(where: { $0.id == holdingAssetId }),
              let previewAnchor,
              isARSupported else { return }

        let point = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let isTwin = AssetRepresentationEntity.isTwin(asset)

        if isTwin {
            guard let hit = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first,
                  let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
            let transform = floorTransform(hit: hit, cameraTransform: cameraTransform)
            previewAnchor.transform = Transform(matrix: transform)
            pendingPreviewTransform = transform
            pendingPreviewIsWall = false
        } else {
            guard let hit = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .vertical).first else { return }
            let (transform, right, up) = wallTransform(hit: hit, asset: asset)
            previewAnchor.transform = Transform(matrix: transform)
            pendingPreviewTransform = transform
            pendingPreviewIsWall = true
            pendingPreviewWallBasis = (right, up)
            pendingPreviewCardHeight = AssetCardEntity.size(for: asset).height
        }
    }

    /// Finalizes the held asset's placement: uses the last raycast-derived
    /// transform if there is one, otherwise falls back to a camera-facing
    /// air placement, then (AR unsupported, e.g. simulator) a fixed
    /// position offset per already-placed asset so multiple fallback
    /// placements don't overlap.
    func confirmHolding() {
        guard let holdingId = holdingAssetId,
              let asset = ownedAssets.first(where: { $0.id == holdingId }),
              let arView else { return }

        var transform: simd_float4x4
        var isWall = false
        var wallBasis: (right: SIMD3<Float>, up: SIMD3<Float>)?
        var cardHeight: Float = 0

        if let pendingPreviewTransform {
            transform = pendingPreviewTransform
            isWall = pendingPreviewIsWall
            wallBasis = pendingPreviewWallBasis
            cardHeight = pendingPreviewCardHeight
        } else if isARSupported, let cameraTransform = arView.session.currentFrame?.camera.transform {
            transform = airTransform(cameraTransform: cameraTransform)
        } else {
            transform = fallbackTransform(index: placementCoords.count)
        }

        if isWall {
            if cardHeight == 0 { cardHeight = AssetCardEntity.size(for: asset).height }
            transform.columns.3.y = snappedWallY(candidateY: transform.columns.3.y, candidateHeight: cardHeight, excludingAssetId: holdingId)
        }

        removePreviewOnly()
        holdingAssetId = nil
        pendingPreviewTransform = nil
        materialize(assetId: holdingId, asset: asset, transform: transform, isWall: isWall, wallBasis: wallBasis, cardHeightOverride: cardHeight)
        selectedAssetId = holdingId
    }

    private func removePreviewOnly() {
        if let previewAnchor {
            arView?.scene.removeAnchor(previewAnchor)
        }
        previewAnchor = nil
    }

    // MARK: - Selection / tap dispatch

    /// Called by `ARContainerView`'s tap gesture with a point in the
    /// `ARView`'s coordinate space.
    func handleTap(at point: CGPoint) {
        guard let arView else { return }

        if holdingAssetId != nil {
            confirmHolding()
            return
        }
        if movingAssetId != nil {
            finishMoving()
            return
        }
        if let hitEntity = arView.entity(at: point), let assetId = ownerAssetId(for: hitEntity) {
            select(assetId)
        } else {
            deselect()
        }
    }

    private func ownerAssetId(for hitEntity: Entity) -> String? {
        for (assetId, live) in liveEntities {
            var current: Entity? = hitEntity
            while let entity = current {
                if entity === live.cardEntity { return assetId }
                current = entity.parent
            }
        }
        return nil
    }

    func select(_ assetId: String) {
        guard liveEntities[assetId] != nil else { return }
        selectedAssetId = assetId
        movingAssetId = nil
        applyHighlights()
    }

    func deselect() {
        selectedAssetId = nil
        applyHighlights()
    }

    private func applyHighlights() {
        for (assetId, live) in liveEntities {
            // Pending/failed styling already sets its own frame state;
            // only touch idle cards here so it isn't overridden.
            guard transferState(for: assetId) == .idle else { continue }
            AssetCardEntity.setHighlighted(assetId == selectedAssetId, on: live.cardEntity)
        }
    }

    // MARK: - Provenance ("来歴")

    func pullProvenanceForSelected() {
        guard let assetId = selectedAssetId,
              var live = liveEntities[assetId],
              let asset = ownedAssets.first(where: { $0.id == assetId }) else { return }
        closeAllProvenanceColumns(except: assetId)
        guard live.provenanceColumn == nil else { return }

        let column = ProvenanceNodeEntity.makeColumn(events: asset.provenance)
        column.position = SIMD3<Float>(
            provenanceColumnX(for: asset, live: live),
            provenanceColumnY(for: live),
            0
        )
        live.anchor.addChild(column)
        live.provenanceColumn = column
        liveEntities[assetId] = live
    }

    var isProvenancePulledForSelected: Bool {
        guard let selectedAssetId else { return false }
        return liveEntities[selectedAssetId]?.provenanceColumn != nil
    }

    private func closeAllProvenanceColumns(except keepId: String?) {
        for (assetId, live) in liveEntities where assetId != keepId {
            guard let column = live.provenanceColumn else { continue }
            column.removeFromParent()
            liveEntities[assetId]?.provenanceColumn = nil
        }
    }

    // MARK: - Move ("動かす")

    /// Wall card: enters drag mode (`pan` slides it along the wall).
    /// Twin: pulls it out of the scene and re-enters the holding-preview
    /// flow so the user re-taps a new floor spot, since a twin was never
    /// draggable (real-world scale, walk-around only).
    func moveSelected() {
        guard let assetId = selectedAssetId,
              let asset = ownedAssets.first(where: { $0.id == assetId }) else { return }

        if AssetRepresentationEntity.isTwin(asset) {
            if let live = liveEntities[assetId] { arView?.scene.removeAnchor(live.anchor) }
            liveEntities[assetId] = nil
            placementCoords[assetId] = nil
            selectedAssetId = nil
            startHolding(assetId: assetId)
        } else {
            movingAssetId = assetId
            selectedAssetId = nil
        }
    }

    func finishMoving() {
        guard let assetId = movingAssetId else { return }
        movingAssetId = nil
        selectedAssetId = assetId
    }

    /// One-finger drag while `movingAssetId` is set: slides that wall card
    /// along its own plane. No-op otherwise (twins are moved by re-holding
    /// instead — see `moveSelected`).
    func pan(translationX: Float, translationY: Float) {
        guard let assetId = movingAssetId,
              let live = liveEntities[assetId],
              let coord = placementCoords[assetId],
              coord.isWallPlacement,
              let right = coord.wallRight,
              let up = coord.wallUp else { return }

        let deltaRight = right * (translationX * Self.wallDragSensitivity)
        let deltaUp = up * (-translationY * Self.wallDragSensitivity)
        live.anchor.position += deltaRight + deltaUp

        var updatedCoord = coord
        updatedCoord.transform = live.anchor.transform.matrix
        placementCoords[assetId] = updatedCoord
    }

    // MARK: - Remove ("外す")

    func removeSelected() {
        guard let assetId = selectedAssetId, let live = liveEntities[assetId] else { return }
        arView?.scene.removeAnchor(live.anchor)
        liveEntities[assetId] = nil
        placementCoords[assetId] = nil
        transferStates[assetId] = nil
        selectedAssetId = nil
    }

    // MARK: - Transfer ("送る")

    func destinationWallet(for asset: TwinfoldAsset) -> String {
        asset.owner == DemoWallet.ownerA.id ? DemoWallet.ownerB.id : DemoWallet.ownerA.id
    }

    var destinationLabelForSelected: String {
        guard let selectedAssetId, let asset = ownedAssets.first(where: { $0.id == selectedAssetId }) else { return "" }
        return DemoWallet.label(forWallet: destinationWallet(for: asset))
    }

    var transferStatesContainPending: Bool {
        transferStates.values.contains(.pending)
    }

    func sendSelected() {
        guard let assetId = selectedAssetId,
              let live = liveEntities[assetId],
              let asset = ownedAssets.first(where: { $0.id == assetId }) else { return }
        let state = transferState(for: assetId)
        guard state == .idle || state == .failed else { return }

        transferStates[assetId] = .pending
        AssetCardEntity.apply(state: .pending, to: live.cardEntity)
        let destination = destinationWallet(for: asset)
        let requestId = UUID().uuidString
        Task { await runTransfer(assetId: assetId, asset: asset, destination: destination, requestId: requestId) }
    }

    /// Overflow menu "失敗をシミュレート (demo)" for the selected asset.
    func simulateFailureForSelected() {
        guard let assetId = selectedAssetId,
              let live = liveEntities[assetId],
              transferState(for: assetId) != .pending else { return }
        transferStates[assetId] = .pending
        AssetCardEntity.apply(state: .pending, to: live.cardEntity)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.failTransfer(assetId: assetId, message: "transfer failed。Retryしてください") }
        }
    }

    private func runTransfer(assetId: String, asset: TwinfoldAsset, destination: String, requestId: String) async {
        if let mock = provider as? MockAssetProvider {
            do {
                _ = try await mock.simulateTransfer(assetId: assetId, to: destination, requestId: requestId)
            } catch {
                await MainActor.run { self.failTransfer(assetId: assetId, message: "transfer failed: \(error)") }
                return
            }
        } else {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }

        do {
            let entitlement = try await provider.refreshOwnership(assetId: assetId)
            await MainActor.run {
                if entitlement.canDisplay {
                    self.failTransfer(assetId: assetId, message: "transfer confirmedですが、このwalletはentitlementを維持しています: \(entitlement.reason)")
                } else {
                    self.confirmTransfer(assetId: assetId, asset: asset, destination: destination)
                }
            }
        } catch {
            await MainActor.run { self.failTransfer(assetId: assetId, message: "entitlement確認に失敗しました: \(error)") }
        }
    }

    /// The card/twin Disappears via the next `loadOwnedAssets` ->
    /// `syncEntities` pass (this session's wallet no longer owns it), not
    /// removed directly here, so other placed assets are untouched.
    private func confirmTransfer(assetId: String, asset: TwinfoldAsset, destination: String) {
        transferStates[assetId] = .confirmed
        if selectedAssetId == assetId { selectedAssetId = nil }
        toast = TransferToast(assetTitle: asset.title, destinationWallet: destination)
        Task { await loadOwnedAssets() }
    }

    /// Keeps the card in place (still placed) and shows a red frame, so
    /// the operation card can offer Retry.
    private func failTransfer(assetId: String, message: String) {
        transferStates[assetId] = .failed
        if let live = liveEntities[assetId] {
            AssetCardEntity.apply(state: .failed, to: live.cardEntity)
        }
        loadErrorMessage = message
    }

    func dismissToast() {
        toast = nil
    }

    /// "〈相手〉の部屋を見る" — switches to the destination wallet so the
    /// just-transferred asset Appears at the same spot.
    func viewDestinationRoom() {
        guard let toast else { return }
        switchWallet(to: DemoWallet.all.first(where: { $0.id == toast.destinationWallet }) ?? .ownerB)
        self.toast = nil
    }

    // MARK: - Reset

    func reset() {
        guard !transferStates.values.contains(.pending) else { return }
        for live in liveEntities.values {
            arView?.scene.removeAnchor(live.anchor)
        }
        liveEntities.removeAll()
        placementCoords.removeAll()
        transferStates.removeAll()
        selectedAssetId = nil
        movingAssetId = nil
        cancelHolding()
        toast = nil
        activeWallet = .ownerA

        if let mock = provider as? MockAssetProvider {
            Task {
                await mock.resetDemoState()
                await loadOwnedAssets()
            }
        } else {
            Task { await loadOwnedAssets() }
        }
    }

    // MARK: - Hint text

    var hintText: String {
        if let selectedAssetId, transferState(for: selectedAssetId) == .pending {
            return "送信中… 確定を待っています"
        }
        if let selectedAssetId, transferState(for: selectedAssetId) == .failed {
            return "送信に失敗。Retryを押す"
        }
        if holdingAssetId != nil {
            return isARSupported
                ? "壁（または床）を検出。タップして置く"
                : "AR非対応のため、タップすると固定位置に置きます"
        }
        if movingAssetId != nil {
            return "ドラッグして動かす。タップで確定"
        }
        if selectedAssetId != nil {
            return "作品をタップすると来歴や送るが出ます"
        }
        return "下から作品を選んで、壁に向ける"
    }

    // MARK: - Placement math

    private func materialize(
        assetId: String,
        asset: TwinfoldAsset,
        transform: simd_float4x4,
        isWall: Bool,
        wallBasis: (right: SIMD3<Float>, up: SIMD3<Float>)?,
        cardHeightOverride: Float = 0
    ) {
        guard let arView else { return }
        let anchor = AnchorEntity(world: transform)
        let entity = AssetRepresentationEntity.make(asset: asset)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)

        var twinFootprint: (width: Float, height: Float)?
        let isTwin = AssetRepresentationEntity.isTwin(asset)
        if isTwin {
            let bounds = entity.visualBounds(relativeTo: anchor)
            entity.position.y -= bounds.min.y
            twinFootprint = (bounds.extents.x, bounds.extents.y)
        }

        liveEntities[assetId] = LiveEntity(anchor: anchor, cardEntity: entity, provenanceColumn: nil, twinFootprint: twinFootprint)
        // Store the exact `transform` parameter, not a read-back of
        // `anchor.transform` — re-materializing the same asset later (a
        // wallet switch, or Appear after a transfer) always passes
        // `coord.transform` straight back into this function, so any
        // read-back here would compound rounding drift across repeated
        // Disappear/Appear cycles instead of reproducing the exact
        // placement.
        placementCoords[assetId] = PlacementCoord(
            transform: transform,
            isWallPlacement: isWall,
            isFloorPlacement: isTwin,
            wallRight: wallBasis?.right,
            wallUp: wallBasis?.up,
            footprintHeight: isWall ? cardHeightOverride : (twinFootprint?.height ?? 0)
        )
        applyHighlights()
    }

    private static func yawFacingCamera(cameraTransform: simd_float4x4) -> Float {
        let cameraForward = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        let headingXZ = SIMD3<Float>(cameraForward.x, 0, cameraForward.z)
        let facing = length(headingXZ) > .ulpOfOne ? -normalize(headingXZ) : SIMD3<Float>(0, 0, 1)
        return atan2(facing.x, facing.z)
    }

    private func airTransform(cameraTransform: simd_float4x4) -> simd_float4x4 {
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let cameraForward = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        let position = cameraPosition + cameraForward * Self.placementDistance
        let rotation = simd_quatf(angle: Self.yawFacingCamera(cameraTransform: cameraTransform), axis: SIMD3<Float>(0, 1, 0))
        var transform = simd_float4x4(rotation)
        transform.columns.3 = SIMD4<Float>(position, 1)
        return transform
    }

    /// Fixed positions for the AR-unsupported (simulator) fallback,
    /// offset by `index` (the number of assets already placed) so
    /// multiple fallback placements don't overlap.
    private func fallbackTransform(index: Int) -> simd_float4x4 {
        var transform = matrix_identity_float4x4
        let xOffset = Float(index) * 0.3 - 0.15
        transform.columns.3 = SIMD4<Float>(xOffset, -0.05, -0.4, 1)
        return transform
    }

    private func wallTransform(hit: ARRaycastResult, asset: TwinfoldAsset) -> (simd_float4x4, SIMD3<Float>, SIMD3<Float>) {
        let cardSize = AssetCardEntity.size(for: asset)
        let hitTransform = hit.worldTransform
        let rawNormal = SIMD3<Float>(hitTransform.columns.1.x, hitTransform.columns.1.y, hitTransform.columns.1.z)
        let flattenedNormal = SIMD3<Float>(rawNormal.x, 0, rawNormal.z)
        let forward = length(flattenedNormal) > .ulpOfOne ? normalize(flattenedNormal) : SIMD3<Float>(0, 0, 1)
        let worldUp = SIMD3<Float>(0, 1, 0)
        let right = normalize(cross(worldUp, forward))
        let up = cross(forward, right)

        let hitPosition = SIMD3<Float>(hitTransform.columns.3.x, hitTransform.columns.3.y, hitTransform.columns.3.z)
        let position = hitPosition + forward * (cardSize.depth / 2 + 0.002)

        var transform = matrix_identity_float4x4
        transform.columns.0 = SIMD4<Float>(right, 0)
        transform.columns.1 = SIMD4<Float>(up, 0)
        transform.columns.2 = SIMD4<Float>(forward, 0)
        transform.columns.3 = SIMD4<Float>(position, 1)
        return (transform, right, up)
    }

    private func floorTransform(hit: ARRaycastResult, cameraTransform: simd_float4x4) -> simd_float4x4 {
        let hitTransform = hit.worldTransform
        let hitPosition = SIMD3<Float>(hitTransform.columns.3.x, hitTransform.columns.3.y, hitTransform.columns.3.z)
        let rotation = simd_quatf(angle: Self.yawFacingCamera(cameraTransform: cameraTransform), axis: SIMD3<Float>(0, 1, 0))
        var transform = simd_float4x4(rotation)
        transform.columns.3 = SIMD4<Float>(hitPosition, 1)
        return transform
    }

    /// If an already-placed wall card's top edge is within
    /// `wallSnapTolerance` of the candidate's top edge, nudge the
    /// candidate's y so the two tops align exactly.
    private func snappedWallY(candidateY: Float, candidateHeight: Float, excludingAssetId: String) -> Float {
        let candidateTop = candidateY + candidateHeight / 2
        for (assetId, coord) in placementCoords where assetId != excludingAssetId && coord.isWallPlacement {
            let existingTop = coord.transform.columns.3.y + coord.footprintHeight / 2
            if abs(existingTop - candidateTop) < Self.wallSnapTolerance {
                return existingTop - candidateHeight / 2
            }
        }
        return candidateY
    }

    private func provenanceColumnX(for asset: TwinfoldAsset, live: LiveEntity) -> Float {
        if let twinFootprint = live.twinFootprint {
            return twinFootprint.width / 2 + 0.02 + ProvenanceNodeEntity.width / 2
        }
        let cardSize = AssetCardEntity.size(for: asset)
        return cardSize.width / 2 + 0.02 + ProvenanceNodeEntity.width / 2
    }

    private func provenanceColumnY(for live: LiveEntity) -> Float {
        guard let twinFootprint = live.twinFootprint else { return 0 }
        return twinFootprint.height / 2
    }
}
