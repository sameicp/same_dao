import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";

module {

    public type Member = {
        name : Text;
        age : Nat;
    };

    public type Result<A, B> = Result.Result<A, B>;

    public type HashMap<A, B> = HashMap.HashMap<A, B>;

    public type Subaccount = Blob;

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type Status = {
        #Open;
        #Accepted;
        #Rejected;
    };

    public type Proposal = {
        id : Nat;
        var status : Status;
        manifest : Text;
        var votes : Int;
        voters : Buffer.Buffer<Principal>;
    };

    public type CreateProposalOk = Nat;

    public type CreateProposalErr = {
        #NotDAOMember;
        #NotEnoughTokens;
    };

    public type CreateProposalResult = Result<CreateProposalOk, CreateProposalErr>;

    public type VoteOk = {
        #ProposalAccepted;
        #ProposalRefused;
        #ProposalOpen;
    };

    public type VoteErr = {
        #ProposalNotFound;
        #AlreadyVoted;
        #ProposalEnded;
        #NotEligibleToVote;
    };

    public type VoteResult = Result<VoteOk, VoteErr>;

};