import SwiftUI
import TwinfoldCore

/// The app's single screen: AR scene ("My Room") with a bottom tray to pick
/// which owned asset to place, plus the overlay chrome for
/// selection/transfer. Replaces the old My Collection list -> per-asset AR
/// screen navigation.
struct MyRoomView: View {
    @State private var controller: RoomController
    @State private var showsFullList = false

    init(provider: any AssetProvider) {
        _controller = State(initialValue: RoomController(provider: provider))
    }

    var body: some View {
        ZStack {
            ARContainerView(controller: controller)
                .ignoresSafeArea()
            RoomOverlayView(controller: controller)
        }
        .safeAreaInset(edge: .bottom) {
            AssetTrayView(controller: controller, showsFullList: $showsFullList)
        }
        .task { await controller.start() }
        .sheet(isPresented: $showsFullList) {
            CollectionView(
                assets: controller.ownedAssets,
                isDemoData: controller.provider.isDemoData,
                isPlaced: { controller.isPlaced($0) }
            )
        }
        .overlay {
            if let loadErrorMessage = controller.loadErrorMessage {
                Text(loadErrorMessage)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
    }
}
