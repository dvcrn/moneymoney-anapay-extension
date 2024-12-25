import RequestHelper;
import JsonHelper;
import lua.Table;

class Anapay {
	public static function login(anaWalletId:String, deviceId:String):{
		emailAuthenticated:Bool,
		loginAuthId:String,
		accessToken:String,
		tokenType:String,
		expiresIn:Int,
		refreshToken:String,
		scope:String
	} {
		var url = "https://teikei1.api.mkpst.com/ana/accounts/login";
		var headers = [
			"host" => "teikei1.api.mkpst.com",
			"accept" => "application/json",
			"user-agent" => "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
			"accept-language" => "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
			"content-type" => "application/json"
		];
		var body = {
			anaWalletId: anaWalletId,
			deviceId: deviceId
		};

		var response = RequestHelper.makeRequest(url, "POST", headers, JsonHelper.stringify(body));
		var parsed = JsonHelper.parse(response.content);

		return {
			emailAuthenticated: parsed.emailAuthenticated,
			loginAuthId: parsed.loginAuthId,
			accessToken: parsed.accessToken,
			tokenType: parsed.tokenType,
			expiresIn: parsed.expiresIn,
			refreshToken: parsed.refreshToken,
			scope: parsed.scope
		};
	}

	public static function getAccounts(accessToken:String):{
		allianceId:String,
		referenceNumber:String,
		accountStatus:String,
		balance:Float,
		mainPaymentSourceId:String,
		creditCardInfo:Dynamic,
		bankPayInfo:Dynamic,
		pointInfo:Dynamic,
		nfcRegisterStatus:String,
		serviceRegisterStatus:String,
		bankpayFirstAuthFlag:Bool
	} {
		if (accessToken == "")
			throw "Access token cannot be empty";

		var url = "https://teikei1.api.mkpst.com/accounts?balanceReferenceFlag=1&nfcStatusReferenceFlag=1";
		var headers = [
			"host" => "teikei1.api.mkpst.com",
			"accept" => "application/json",
			"user-agent" => "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
			"authorization" => "Bearer " + accessToken,
			"accept-language" => "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
			"content-type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, "GET", headers);
		var parsed = JsonHelper.parse(response.content);

		return {
			allianceId: parsed.allianceId,
			referenceNumber: parsed.referenceNumber,
			accountStatus: parsed.accountStatus,
			balance: parsed.balance,
			mainPaymentSourceId: parsed.mainPaymentSourceId,
			creditCardInfo: parsed.creditCardInfo,
			bankPayInfo: parsed.bankPayInfo,
			pointInfo: parsed.pointInfo,
			nfcRegisterStatus: parsed.nfcRegisterStatus,
			serviceRegisterStatus: parsed.serviceRegisterStatus,
			bankpayFirstAuthFlag: parsed.bankpayFirstAuthFlag
		};
	}

	public static function getTransactions(accessToken:String, ?pageNumber:Int = 1, ?pageSize:Int = 999):Array<{
		saleDatetime:String,
		settlementType:String,
		dealType:String,
		delKbn:String,
		descriptionType:String,
		shopName:String,
		amount:Float,
		walletSettlementNo:String,
		walletSettlementSubNo:String,
		pointConversionAmount:Float
	}> {
		var url = 'https://teikei1.api.mkpst.com/salesDetails?pageSize=${pageSize}&pageNumber=${pageNumber}&historyType=&settlementType=';
		var headers = [
			"host" => "teikei1.api.mkpst.com",
			"accept" => "application/json",
			"user-agent" => "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
			"authorization" => "Bearer " + accessToken,
			"accept-language" => "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
			"content-type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, "GET", headers);
		var parsed = JsonHelper.parse(response.content);

		var result:Array<{
			saleDatetime:String,
			settlementType:String,
			dealType:String,
			delKbn:String,
			descriptionType:String,
			shopName:String,
			amount:Float,
			walletSettlementNo:String,
			walletSettlementSubNo:String,
			pointConversionAmount:Float
		}> = Table.toArray(parsed.history);

		trace("parsed----");
		trace(parsed);

		trace("result ---");
		trace(result);

		trace("result (first) ---");
		trace(result[0]);

		return result;
	}
}
