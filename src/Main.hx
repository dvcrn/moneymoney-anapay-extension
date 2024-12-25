import lua.Table;
import RequestHelper;
import JsonHelper;
import haxe.Int64Helper;
import Sanitizer;

enum abstract AccountType(String) {
	var AccountTypeGiro = "AccountTypeGiro";
	var AccountTypeSavings = "AccountTypeSavings";
	var AccountTypeFixedTermDeposit = "AccountTypeFixedTermDeposit";
	var AccountTypeLoan = "AccountTypeLoan";
	var AccountTypeCreditCard = "AccountTypeCreditCard";
	var AccountTypePortfolio = "AccountTypePortfolio";
	var AccountTypeOther = "AccountTypeOther";
}

typedef Account = {
	?name:String,
	?owner:String,
	?accountNumber:String,
	?subAccount:String,
	?portfolio:Bool,
	?bankCode:String,
	?currency:String,
	?iban:String,
	?bic:String,
	?balance:Float,
	type:AccountType
}

typedef Transaction = {
	?name:String,
	?accountNumber:String,
	?bankCode:String,
	?amount:Float,
	?currency:String,
	?bookingDate:Int,
	?valueDate:Int,
	?purpose:String,
	?transactionCode:haxe.Int64,
	?textKeyExtension:Int,
	?purposeCode:String,
	?bookingKey:String,
	?bookingText:String,
	?primanotaNumber:String,
	?batchReference:String,
	?endToEndReference:String,
	?mandateReference:String,
	?creditorId:String,
	?returnReason:String,
	?booked:Bool
}

typedef Security = {
	?name:String,
	?isin:String,
	?securityNumber:String,
	?quantity:Float,
	?currencyOfQuantity:String,
	?purchasePrice:Float,
	?currencyOfPurchasePrice:String,
	?exchangeRateOfPurchasePrice:Float,
	?price:Float,
	?currencyOfPrice:String,
	?exchangeRateOfPrice:Float,
	?amount:Float,
	?originalAmount:Float,
	?currencyOfOriginalAmount:String,
	?market:String,
	?tradeTimestamp:Int
}

class Main {
	@:expose("dosomething")
	static function dosomething() {
		trace("dosomething dosomething");
	}

	@:luaDotMethod
	@:expose("SupportsBank")
	static function SupportsBank(protocol:String, bankCode:String) {
		trace("ANAPAY SupportsBank got called");
		trace(protocol);
		trace(bankCode);

		return bankCode == "ANA Pay Wallet";
	}

	@:luaDotMethod
	@:expose("InitializeSession")
	static function InitializeSession(protocol:String, bankCode:String, username:String, reserved, password:String) {
		trace("InitializeSession: got called");
		trace("InitializeSession: protocol = " + protocol);
		trace("InitializeSession: bankCode = " + bankCode);
		trace("InitializeSession: username = " + username);
		trace("InitializeSession: reserved = " + reserved);
		trace("InitializeSession: password = " + password);

		var result = Anapay.login(username, password);
		trace(result);

		Storage.set("accessToken", result.accessToken);
	}

	@:luaDotMethod
	@:expose("ListAccounts")
	static function ListAccounts(knownAccounts) {
		trace("ListAccounts got called");
		trace(knownAccounts);

		var accessToken = Storage.get("accessToken");

		trace("accessToken = " + accessToken);
		if (accessToken == null) {
			throw "Access token not set";
		}

		var accounts = Anapay.getAccounts(accessToken);

		trace("discovered account: " + accounts.referenceNumber + " balance: " + accounts.balance);

		var account:Account = {
			name: "ANA Pay",
			accountNumber: accounts.referenceNumber,
			currency: "JPY",
			balance: accounts.balance,
			type: AccountType.AccountTypeCreditCard,
		};

		Storage.set("account", JsonHelper.stringify(account));
		return Table.fromArray([account]);
	}

	@:luaDotMethod
	@:expose("RefreshAccount")
	static function RefreshAccount(account:{
		iban:String,
		bic:String,
		comment:String,
		bankCode:String,
		owner:String,
		attributes:Dynamic,
		subAccount:String,
		currency:String,
		name:String,
		balance:Float,
		portfolio:Bool,
		type:String,
		balanceDate:Float,
		accountNumber:String
	}, since:Float) {
		trace("RefreshAccount got called");
		trace(account);
		trace(since);

		var accessToken = Storage.get("accessToken");
		trace("accessToken = " + accessToken);
		if (accessToken == null) {
			throw "Access token not set";
		}

		var storedAccount = JsonHelper.parse(Storage.get("account"));

		var accounts = Anapay.getAccounts(accessToken);
		var account:Account = {
			name: "ANA Pay",
			accountNumber: accounts.referenceNumber,
			currency: "JPY",
			balance: accounts.balance,
			type: AccountType.AccountTypeCreditCard,
		};

		trace("refreshing account " + accounts.referenceNumber + " balance=" + accounts.balance);

		var transactions:Array<Transaction> = [];
		var page = 1;
		var hasMore = true;
		while (hasMore) {
			var result = Anapay.getTransactions(accessToken, page);

			trace("got " + result.length + " transactions");

			if (result.length == 0) {
				hasMore = false;
				break;
			} else {
				for (transaction in result) {
					trace("Processing transaction " + " amount=" + transaction.amount + " payee=" + transaction.shopName);

					// date looks like this: 20241223122455
					var year = Std.parseInt(transaction.saleDatetime.substr(0, 4));
					var month = Std.parseInt(transaction.saleDatetime.substr(4, 2));
					var day = Std.parseInt(transaction.saleDatetime.substr(6, 2));
					var hour = Std.parseInt(transaction.saleDatetime.substr(8, 2));
					var minute = Std.parseInt(transaction.saleDatetime.substr(10, 2));
					var second = Std.parseInt(transaction.saleDatetime.substr(12, 2));

					var date = new Date(year, month - 1, day, hour, minute, second);
					var timestamp = Std.int(date.getTime() / 1000);

					trace("timestamp " + timestamp);

					if (timestamp < since) {
						hasMore = false;
						break;
					}

					trace("parsed timestamp " + timestamp);

					var amount = -transaction.amount;
					// dealType 05 delKbn 01 = addition (charge)
					// dealType 06 delKbn 01 = addition (Cashback)
					if (transaction.dealType == "05" || transaction.dealType == "06" || transaction.delKbn == "02" || transaction.delKbn == "07"
						|| transaction.delKbn == "08") {
						amount = transaction.amount;
					}

					var bookingText = transaction.descriptionType;
					if (transaction.dealType == "05") {
						bookingText = "チャージ";
					} else if (transaction.dealType == "06") {
						bookingText = "キャッシュバック";
					} else if (transaction.descriptionType == "3001") {
						bookingText = "クレジットカード";
					} else if (transaction.descriptionType == "3006") {
						bookingText = "Apple Pay";
					} else if (transaction.descriptionType == "3007") {
						bookingText = "キャッシュバック";
					} else if (transaction.descriptionType == "3009") {
						bookingText = "オートチャージ";
					} else if (transaction.descriptionType == "1017") {
						bookingText = "バーチャルプリペイドカード";
					} else if (transaction.descriptionType == "1018") {
						bookingText = "VISAタッチ払い";
					} else if (transaction.descriptionType == "1019") {
						bookingText = "iDタッチ払い";
					} else {
						bookingText = "Unknown Type";
					}

					var name = transaction.shopName;
					if (name == "") {
						name = bookingText;
					} else {
						var sanitizedName = Sanitizer.sanitize(transaction.shopName);
						trace("Name: " + name + " -> " + sanitizedName);

						name = sanitizedName;
					}

					transactions.push({
						name: name,
						amount: amount,
						currency: account.currency,
						bookingDate: timestamp,
						valueDate: timestamp,
						bookingText: bookingText,
						// transactionCode: Int64Helper.parseString(transaction.walletSettlementNo),
						purposeCode: transaction.descriptionType,
						booked: true
					});
				}
				page++;
			}
		}

		trace("received # transactions: " + transactions.length);
		trace("first converted from list: " + transactions[0]);

		return {
			balance: account.balance,
			transactions: Table.fromArray(transactions),
		}
	}

	@:luaDotMethod
	@:expose("EndSession")
	static function EndSession() {
		trace("EndSession got called");
	}

	function nonstatic() {
		trace("ooooo");
	}

	static function main() {
		untyped __lua__("
        WebBanking {
            version = 1.0,
            url = 'https://ana.co.jp',
            description = 'ANA Pay Wallet Integration',
            services = { 'ANA Pay Wallet' },
        }
        ");

		untyped __lua__("
        function SupportsBank(protocol, bankCode)
            return _hx_exports.SupportsBank(protocol, bankCode)
        end
        ");

		untyped __lua__("
        function InitializeSession(protocol, bankCode, username, reserved, password)
            return _hx_exports.InitializeSession(protocol, bankCode, username, reserved, password)
        end
        ");

		untyped __lua__("
        function RefreshAccount(account, since)
            return _hx_exports.RefreshAccount(account, since)
        end
        ");

		untyped __lua__("
        function ListAccounts(knownAccounts)
            return _hx_exports.ListAccounts(knownAccounts)
        end
        ");

		untyped __lua__("
        function EndSession()
            return _hx_exports.EndSession()
        end
        ");
	}
}
