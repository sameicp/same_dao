import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import Order "mo:base/Order";
import Array "mo:base/Array";
actor {
    var name: Text = "Same";

    type Age = Nat;

    // Variant type
    // usually used with switch cases
    type Genda = {
        #male: Text;
        #female: Text;
    };

    type Natural = {
        #N: Nat;
    };

    type Integer = {
        #I: Int;
    };

    type Floating = {
        #F: Float;
    };

    type MyResult = Result.Result<Text, Text>;

    type Number = Natural or Integer or Floating;

    type Student = {
        name: Text;
        surname: Text;
        age: Nat;
        course: Text;
    };

    let numbers: [Nat] = [23, 33, 0, 43, 10, 7];
    let base: Nat = 10;

    func add(a: Nat, b: Nat): Nat {
        return a + b;
    };

    func make_nat<T <: Number>(x: T): Natural {
        switch(x) {
            case(#N n ) { 
                return #N n;
             };
            case(#I i) { 
                return #N(Int.abs(i));
            };
            case(#F f) {
                let rounded = Float.nearest(f);
                let integer = Float.toInt(rounded);
                let natural = Int.abs(integer);
                return #N natural;
            };
        };
    };

    func make_float<T <: Number>(num: T): Float {
        switch (num) {
            case (#N n) {
                return Float.fromInt(n);
            };
            case (#I i) {
                return Float.fromInt(i);
            };
            case (#F f) {
                return f;
            };
        };
    };

    public func sum_numbers(): async Nat {
        return Array.foldLeft<Nat, Nat>(numbers, base, add);
    };

    public func set_name(_name: Text): async () {
        name := _name;
    };

    public query func get_name() : async Text {
        return name;
    };

    public func get_genda(): async Genda {
        let baby: Genda = #male name;

        switch(baby) {
            case(#male m) { 
                return #male m;
             };
            case(#female f) { 
                return #female f;
            };
        };
    };

    public func create_student(name: Text, surname: Text, age: Nat): async Student {
        return {
            name;
            surname;
            age;
            course = "Computational Thinking";
        };
    };

    public func test_make_nat(): async () {
        assert make_nat(#N 0) == #N 0;
        assert make_nat(#I(-4)) == #N 4;
        assert make_nat(#F(-5.6)) == #N 6;
    };

    public shared query({caller}) func whoami(): async MyResult {
        if(Principal.isAnonymous(caller)) {
            return  #err("You have an Anonymous ID: " # Principal.toText(caller));
        } else {
            return #ok("You have a legit ID: " # Principal.toText(caller));
        };
    };

    public func compare(first: Nat, second: Nat): async Text {
        let val: Order.Order = Nat.compare(first, second);

        switch(val) {
            case(#less) { 
                return Nat.toText(first) # " is less than " # Nat.toText(second);
             };
            case(#equal) {
                return Nat.toText(first) # " is equal to " # Nat.toText(second);
             };
             case(#greater) {
                return Nat.toText(first) # " is greater than " # Nat.toText(second);
             };
        };
    };

    public func square_root(num: Number): async Float {
        let float_num = make_float(num);
        return Float.sqrt(float_num);
    };

    public func area_circle(rad: Float): async Float {
        return Float.pi * Float.pow(rad, 2);
    };

    public shared({caller}) func whoami_blob(): async [Nat8] {
        return Blob.toArray(Principal.toBlob(caller));
    };
}