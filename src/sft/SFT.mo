import Account "../module/account";
import Type "../module/types";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";

actor SFT {
    stable var totalSupply: Nat = 0;
    stable let nameToken: Text = "Same Future Token";
    stable let symbolToken: Text = "SFT";

    let ledger : TrieMap.TrieMap<Type.Account, Nat> = TrieMap.TrieMap(Account.accountsEqual, Account.accountsHash);

    public query func tokenName() : async Text {
        return nameToken;
    };

    public query func tokenSymbol() : async Text {
        return symbolToken;
    };

    public query func getTotalSupply(): async Nat {
        return totalSupply;
    };

    // public query func getTotalSupply() : async Nat {
    //     var total = 0;
    //     for (balance in ledger.vals()) {
    //         total += balance;
    //     };
    //     return total;
    // };

    func getBalance(account: Type.Account): Nat {
        return switch (ledger.get(account)) {
            case (null) { 0 };
            case (?some) { some };
        };
    };

    public query func balanceOf(account : Type.Account) : async Nat {
        return getBalance(account);
    };

    public func mint(owner : Principal, amount : Nat) : async Type.Result<(), Text> {
        if (Principal.isAnonymous(owner)) {
            return #err("Can not mint " # symbolToken);
        };

        let defaultAccount: Type.Account = { owner = owner; subaccount = null };

        switch (ledger.get(defaultAccount)) {
            case (null) {
                ledger.put(defaultAccount, amount);
            };
            case (?some) {
                ledger.put(defaultAccount, some + amount);
            };
        };
        totalSupply += amount;

        return #ok(());
    };

    public func transfer(from : Type.Account, to : Type.Account, amount : Nat): async Type.Result<(), Text> {
        let fromBalance = getBalance(from);

        if (fromBalance < amount) {
            return #err("Not enough balance");
        };

        let toBalance = getBalance(to);

        ledger.put(from, fromBalance - amount);
        ledger.put(to, toBalance + amount);

        return #ok();
    };

    public func updateBalance(account: Type.Account, value: Nat): async () {
        ledger.put(account, value);
    };
};