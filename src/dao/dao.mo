import Account "../module/account";
import Type "../module/types";
import SFT "canister:sft";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

actor class DAO() {

    let minTokenForCreatingProposal: Nat = 5;
    let initalTokenForMember: Nat = 10;
    let tokenToVoteForProposal: Nat = 1;
    var proposalId: Nat = 0;
    var maxVoters: Nat = 2;
    var tokenSymbol: Text = "";
    var tokenName: Text = "";

    let name : Text = "Same Future DAO";
    var manifesto : Text = "Empower the next wave of builders to make the Web3 revolution a reality";

    let dao : Type.HashMap<Principal, Type.Member> = HashMap.HashMap<Principal, Type.Member>(0, Principal.equal, Principal.hash);
    let goals : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0); // 0 is the initial length of Buffer.
    let proposals: Buffer.Buffer<Type.Proposal> = Buffer.Buffer<Type.Proposal>(0);

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public query func getAllDaoMembers() : async [Type.Member] {
        return Iter.toArray(dao.vals());
    };

    public query func numberOfDaoMembers() : async Nat {
        return dao.size();
    };

    public shared query func getDaoGoals() : async [Text] {
        return Buffer.toArray(goals);
    };

    public shared({caller}) func checkBalance(account : Type.Account) : async Type.Result<Nat, Text> {
        if (Principal.notEqual(caller, account.owner)) {
            return #err("You are not the owner of the account");
        };

        return #ok(await SFT.balanceOf(account));
    };

    public func totalSftSupply() : async Nat {
        return await SFT.getTotalSupply();
    };

    public shared({caller}) func addGoal(newGoal : Text) : async Type.Result<(), Text> {
        switch(dao.get(caller)) {
            case(null) {
                return #err("You can not add your goal.")
            };
            case(?member) {
                goals.add(newGoal);
                return #ok(());
            };
        };
    };

    public shared ({ caller }) func joinDao(member : Type.Member) : async Type.Result<Text, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Can not register an anonymous ID");
        };

        if (dao.size() == 0) {
            await setTokenInfo();
        };

        switch (dao.get(caller)) {
            case (?member) {
                return #err("Already a member");
            };
            case (null) {
                dao.put(caller, member);
                switch(await mintSFT(caller, initalTokenForMember)) {
                    case(#err m) {
                        return #err(m);
                    };
                    case(#ok(m)) {
                        return #ok("You are now a member of " # name # ", " # Nat.toText(initalTokenForMember) # " " # tokenSymbol # " deposited to your account");
                    }
                }
            };
        };
    };

    public shared ({ caller }) func updateDaoMember(member : Type.Member) : async Type.Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member_info) {
                dao.put(caller, member);
                return #ok(());
            };
            case (null) {
                return #err("You are not a member of " # name);
            };
        };
    };

    public shared ({ caller }) func exitDao() : async Type.Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                dao.delete(caller);
                return #ok(());
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    public query func checkDaoMember(memberPrincipal : Principal) : async Type.Result<Type.Member, Text> {
        switch (dao.get(memberPrincipal)) {
            case (?member) {
                return #ok(member);
            };
            case (null) {
                return #err("You are not a member of " # name);
            };
        };
    };

    public shared ({ caller }) func transferSFT(from : Type.Account, to : Type.Account, amount : Nat) : async Type.Result<Text, Text> {
        if (Principal.notEqual(caller, from.owner)) {
            return #err("Owner is allowed to transfer tokens.");
        };

        switch(await SFT.transfer(from, to, amount)) {
            case(#err m) {
                return #err(m)
            };
            case(#ok(())) {
                return #ok("Transfer was successful.")
            }
        }
    };

    public shared ({ caller }) func createProposal(manifest : Text) : async Type.CreateProposalResult {
        switch (dao.get(caller)){
            case (null) {
                return #err(#NotDAOMember);
            };
            case (?member) {
                let account: Type.Account = {
                    owner = caller;
                    subaccount = null;
                };
                
                let balance: Nat = await SFT.balanceOf(account);

                if (balance < minTokenForCreatingProposal) {
                    return #err(#NotEnoughTokens);
                };

                // Creating a proposal.

                var proposal: Type.Proposal = {
                    id = proposalId;
                    var status = #Open;
                    manifest;
                    var votes = 0;
                    voters = Buffer.Buffer<Principal>(0);
                };
                proposalId += 1;

                await SFT.updateBalance(account, balance - minTokenForCreatingProposal);
                proposals.add(proposal);

                return #ok(proposal.id)
            };
        };
    };

    public query func getProposalManifest(id : Nat) : async Type.Result<Text, Text> {
        let proposal: ?Type.Proposal = _getProposal(id);
        switch(proposal) {
            case (null) {
                return #err("No Proposal found.");
            };
            case (?proposal) {
                return #ok(proposal.manifest);
            }
        }
    };

    public shared ({ caller }) func voteForProposal(proposalId : Nat, vote : Bool) : async Type.VoteResult {
        switch(dao.get(caller)) {
            case (null) {
                return #err(#NotEligibleToVote)
            };
            case (?some) {
                let account: Type.Account = {
                    owner = caller;
                    subaccount = null;
                };

                let balance: Nat = await SFT.balanceOf(account);

                if (balance < tokenToVoteForProposal) {
                    return #err(#NotEligibleToVote)
                };

                let proposal: ?Type.Proposal = _getProposal(proposalId);

                switch(proposal) {
                    case(null) {
                        return #err(#ProposalNotFound)
                    };
                    case(?prop) {
                        switch(prop.status) {
                            case(#Accepted) {
                                return #err(#ProposalEnded)
                            };
                            case (#Rejected) {
                                return #err(#ProposalEnded)
                            };
                            case (#Open) {
                                switch (prop.voters.size() == 0) {
                                    case(true) {
                                        if (vote) {
                                            prop.votes += 1;
                                        } else {
                                            prop.votes -= 1;
                                        };

                                        await SFT.updateBalance(account, balance - tokenToVoteForProposal);
                                        prop.voters.add(caller);

                                        return #ok(#ProposalOpen)

                                    };
                                    case (false) {
                                        if (prop.votes <= Int.neg(maxVoters)) {
                                            return #ok(#ProposalRefused);
                                        };

                                        if (prop.votes >= maxVoters) {
                                            return #ok(#ProposalAccepted);
                                        };

                                        if (votedBefore(caller, prop.voters)) {
                                            return #err(#AlreadyVoted);
                                        };

                                        if (vote) {
                                            prop.votes += 1;
                                        } else {
                                            prop.votes -= 1;
                                        };

                                        await SFT.updateBalance(account, balance - tokenToVoteForProposal);
                                        prop.voters.add(caller);

                                        if (prop.votes >= maxVoters) {
                                            prop.status := #Accepted;
                                            setManifesto(prop.manifest);
                                            return #ok(#ProposalAccepted);
                                        };

                                        if (prop.votes <= Int.neg(maxVoters)) {
                                            prop.status := #Rejected;
                                            return #ok(#ProposalRefused);
                                        };

                                        return #ok(#ProposalOpen);
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    func votedBefore(id:Principal, voters: Buffer.Buffer<Principal>): Bool {
        let votersArray = Buffer.toArray<Principal>(voters);
        func check(arg : Principal) : Bool {
            arg == id
        };

        let voter: ?Principal = Array.find<Principal>(votersArray, check);
        
        return switch(voter) {
            case(null) {
                false
            };
            case(?voter) {
                true
            };
        };
    };

    func setManifesto(newManifesto : Text) : () {
        manifesto := newManifesto;
        return;
    };

    func _getProposal(id:Nat): ?Type.Proposal {
        let proposalsArray = Buffer.toArray<Type.Proposal>(proposals);
        func check(arg : Type.Proposal) : Bool {
            arg.id == id
        };

        let proposal: ?Type.Proposal = Array.find<Type.Proposal>(proposalsArray, check);

        return proposal;
    };

    func mintSFT(owner : Principal, amount : Nat) : async Type.Result<Text, Text> {
        switch(await SFT.mint(owner, amount)) {
            case(#err m) { 
                return #err(m);
             };
            case(#ok(())) { 
                return #ok("Successful.");
            };
        };
    };

    func setTokenInfo(): async() {
        tokenSymbol := await SFT.tokenSymbol();
        tokenName := await SFT.tokenName();
    };

    public shared query ({ caller }) func whoami() : async Principal {
        return caller;
    };

};
