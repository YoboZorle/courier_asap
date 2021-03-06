import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:pickrr_app/src/helpers/db/business.dart';
import 'package:pickrr_app/src/helpers/db/driver.dart';
import 'package:pickrr_app/src/helpers/utility.dart';
import 'package:pickrr_app/src/models/business.dart';
import 'package:pickrr_app/src/models/driver.dart';
import 'package:pickrr_app/src/models/user.dart';
import 'package:pickrr_app/src/services/exceptions.dart';
import 'package:pickrr_app/src/services/http_client.dart';
import 'package:pickrr_app/src/services/repositories/driver.dart';

class BusinessRepository extends APIClient {
  Response response;

  BusinessRepository() {
    interceptor('drivers');
  }

  applicationRequest(FormData details) async {
    final String url = '/business/application';

    try {
      await dio.post(url, data: details);
    } catch (e) {
      cprint(e.response, errorIn: 'applicationRequest');
      if (e.response.data != null &&
          e.response.data['non_field_errors'] != null) {
        throw ServiceError(e.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed please try again.');
    }
  }

  createPin(FormData details) async {
    final String url = '/business/details';

    try {
      await dio.patch(url, data: details);
    } catch (err) {
      cprint(err.response, errorIn: 'createPin');
      if (err.response.data != null &&
          err.response.data['non_field_errors'] != null) {
        throw ServiceError(err.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed, please try again.');
    }
  }

  verifyPin(FormData details) async {
    final String url = '/business/verify-pin';

    try {
      response = await dio.post(url, data: details);
      final responseBody = response.data;
      return responseBody;
    } catch (err) {
      cprint(err.response, errorIn: 'verifyPin');
      if (err.response.data != null &&
          err.response.data['non_field_errors'] != null) {
        throw ServiceError(err.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed, please try again.');
    }
  }

  forgotPin() async {
    final String url = '/business/forgot-pin';

    try {
      response = await dio.post(url);
      final responseBody = response.data;
      return responseBody;
    } catch (err) {
      cprint(err.response, errorIn: 'verifyPin');
      if (err.response.data != null &&
          err.response.data['non_field_errors'] != null) {
        throw ServiceError(err.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed, please try again.');
    }
  }

  getBusinessFromStorage(businessId) async {
    BusinessProvider helper = BusinessProvider.instance;
    Business business = await helper.getBusiness(businessId);
    return business;
  }

  Future<void> _persistBusinessDetails(rawData) async {
    BusinessProvider helper = BusinessProvider.instance;
    Business business = Business.fromMap(rawData);
    await helper.updateOrInsert(business);
  }

  Future getBusinessDetails() async {
    final String url = '/business/details';
    response = await dio.get(url);
    final responseBody = response.data;
    return responseBody;
  }

  loadBusinessDetailsToStorage(int userId) async {
    var businessResponse = await getBusinessDetails();
    await _persistBusinessDetails(businessResponse);
  }

  Future<void> persistBusinessDetails(rawData) async {
    await _persistBusinessDetails(rawData);
  }

  Future<dynamic> getBusinessTransactions({int page}) async {
    final String url = '/business/transactions?page=$page';
    try {
      Response response = await dio.get(url);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<dynamic> getAvailableRiders({int page, String query}) async {
    Map<String, dynamic> queryParams = {'query': query, 'page': page};
    final String url = '/business/available-riders';
    try {
      Response response = await dio.get(url, queryParameters: queryParams);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<dynamic> getAllRiders({int page, String query}) async {
    Map<String, dynamic> queryParams = {'query': query, 'page': page};
    final String url = '/business/riders';
    try {
      Response response = await dio.get(url, queryParameters: queryParams);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<void> assignRiderToRide(FormData details) async {
    final String url = '/business/assign-to-ride';

    try {
      response = await dio.post(url, data: details);
      final responseBody = response.data;
      return responseBody;
    } catch (err) {
      cprint(err.response, errorIn: 'assignRiderToRide');
      if (err.response.data != null &&
          err.response.data['non_field_errors'] != null) {
        throw ServiceError(err.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed, please try again.');
    }
  }

  Future<void> registerRider(FormData details) async {
    final String url = '/business/register-rider';

    try {
      response = await dio.post(url, data: details);
      final responseBody = response.data;
      return responseBody;
    } catch (err) {
      cprint(err.response, errorIn: 'assignRiderToRide');
      if (err.response.data != null &&
          err.response.data['non_field_errors'] != null) {
        throw ServiceError(err.response.data['non_field_errors'].first);
      }
      throw ServiceError('Request failed, please try again.');
    }
  }

  Future<Driver> getDriverFromStorage(int riderId) async {
    DriverProvider helper = DriverProvider.instance;
    Driver driver = await helper.getDriver(riderId);
    if (driver.businessId != null) {
      BusinessProvider businessDBHelper = BusinessProvider.instance;
      Business business = await businessDBHelper.getBusiness(driver.businessId);
      driver.setCompany = business;
    }
    if (driver.id != null) {
      User userDetails = await getPersistedUserDetails(driver.id);
      driver.details = userDetails;
    }
    return driver;
  }

  Future<dynamic> getRiderCurrentRide(int riderId) async {
    final String url = '/business/active-ride/$riderId';
    try {
      Response response = await dio.get(url);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<void> updateDriverStatus({String status, int riderId}) async {
    final String url = '/business/update-rider-status';
    response =
        await dio.patch(url, data: {'status': status, 'rider_id': riderId});
    final responseBody = response.data;
    await DriverRepository().persistDriverDetails(responseBody);
  }

  Future<void> updateRiderBlockingStatus({String status, int riderId}) async {
    final String url = '/business/$riderId/rider-blocking';
    response = await dio.post(url, data: {'blocking_state': status});
    final responseBody = response.data;
    await DriverRepository().persistDriverDetails(responseBody);
  }

  Future<dynamic> getRatedRidesBusiness(int riderId,
      {@required int page}) async {
    final String url = '/business/rider-reviews?page=$page&rider_id=$riderId';
    try {
      Response response = await dio.get(url);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<dynamic> getRiderHistory(int riderId, {@required int page}) async {
    final String url =
        '/business/rider-order-history?page=$page&rider_id=$riderId';
    try {
      Response response = await dio.get(url);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }

  Future<dynamic> getRiderTransactions(int riderId,
      {@required int page}) async {
    final String url =
        '/business/rider-transactions?page=$page&rider_id=$riderId';
    try {
      Response response = await dio.get(url);
      final responseBody = response.data;
      return responseBody;
    } catch (e) {
      throw ServiceError('Request failed please try again.');
    }
  }
}
