// ================= Search Place Page =================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:wiki_places/global/utils.dart';
import 'package:wiki_places/widgets/appbar.dart';
import 'package:wiki_places/widgets/change_radius_slider.dart';
import 'package:wiki_places/controllers/store_controller.dart';
import 'package:wiki_places/global/types.dart';
import 'package:wiki_places/widgets/filters.dart';
import 'package:wiki_places/widgets/search_place_widget.dart';

class SearchPlacePage extends StatefulWidget {
  SearchPlacePage({Key? key, this.afterSearchCallback}) : super(key: key);
  final Function? afterSearchCallback;

  @override
  State<SearchPlacePage> createState() => _SearchPlacePageState();
}

class _SearchPlacePageState extends State<SearchPlacePage> {
  final _storeController = Get.put(StoreController());
  late final TextEditingController _placeNameController = TextEditingController(text: _storeController.placeName.value);
  late final PrimitiveWrapper _placeModeController = PrimitiveWrapper(_storeController.placeMode.value);
  late final PrimitiveWrapper _radiusController = PrimitiveWrapper(double.parse(_storeController.radius.value));
  bool _isLoading = false;
  Json _previousStore = {};

  @override
  void dispose() {
    _placeNameController.dispose();
    super.dispose();
  }

  void updateIsLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _savePreviousStore() {
    _previousStore = {
      'radius': _storeController.radius.value,
      'placeCoordinates': _storeController.placeCoordinates.value,
      'placeName': _storeController.placeName.value,
      'placeMode': _storeController.placeMode.value
    };
  }

  void _restorePreviousStore() {
    _storeController.setStore(_previousStore);
  }

  void _searchPlace() async {
    if (_radiusController.value == 0) {
      displaySnackbar(
        title: 'strError'.tr,
        content: 'strRadiusMustBePositive'.tr
      );
      return;
    }

    if (_placeNameController.text == "") {
      displaySnackbar(
          title: 'strError'.tr,
          content: 'strEmptyPlaceName'.tr
      );
      return;
    }

    updateIsLoading(true);
    _savePreviousStore();

    if (_placeModeController.value == EPlaceMode.current) {
      await _storeController.updatePlaceToCurrentMode();

    } else {
      bool isPlaceExist = await _storeController.updatePlaceToOtherMode(otherPlace: _placeNameController.text);
      if (!isPlaceExist) {
        displaySnackbar(
            title: 'strError'.tr,
            content: 'strPlaceNotExist'.tr
        );
        updateIsLoading(false);
        return;
      }
    }

    _storeController.updateRadius(_radiusController.value.toString());
    if (await _storeController.updatePlacesCollection()) {
      navigateBack();
      displaySearchSuccessfully();
      if (widget.afterSearchCallback != null) {
        widget.afterSearchCallback!();
      }

    } else {
      _restorePreviousStore();
    }

    updateIsLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: WikiPlacesAppBar(title: 'strSearchPlaceAround'.tr),
        body: Column(
          children: [
            SearchPlaceWidget(placeNameController: _placeNameController, placeModeController: _placeModeController),
            const Divider(),
            const Filters(),
            const Divider(),
            ChangeRadiusSlider(controller: _radiusController),
            ElevatedButton(onPressed: _searchPlace, child: Text('strSearch'.tr)),
          ],
        ),
      ),
    );
  }
}
