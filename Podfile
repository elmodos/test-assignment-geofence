# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
use_frameworks!

def shared_pods
    pod 'RxSwift', '~> 4'
    pod 'RxCocoa', '~> 4'
end

target 'CoreGeoFence' do
    shared_pods
end

target 'CoreGeoFenceTests' do
    inherit! :search_paths
end

target 'geofence' do
    shared_pods
    pod 'LocationPickerViewController'
end
