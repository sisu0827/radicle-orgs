// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ENS {
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
}

interface ReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
}

/// A Radicle Org.
contract OrgV1 {
    /// Project anchor.
    struct Anchor {
        // The hash being anchored in multihash format.
        bytes multihash;
        // The kind of object being anchored.
        uint8 kind;
    }

    /// Output of namehash("addr.reverse").
    bytes32 public constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    /// Org owner.
    address public owner;

    /// Latest anchor for each object.
    mapping (bytes32 => Anchor) public anchors;

    // -- EVENTS --

    /// An object was anchored.
    event Anchored(bytes32 id, bytes multihash, uint8 kind);

    /// An object was unanchored.
    event Unanchored(bytes32 id);

    /// The org owner changed.
    event OwnerChanged(address newOwner);

    /// The org name changed.
    event NameChanged(string name);

    /// Construct a new org instance, by providing an owner address.
    constructor(address _owner) {
        owner = _owner;
    }

    // -- OWNER METHODS --

    /// Functions that can only be called by the org owner.
    modifier ownerOnly {
        require(msg.sender == owner, "Org: Only the org owner can perform this action");
        _;
    }

    /// Set the org owner.
    function setOwner(address newOwner) public ownerOnly {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /// Anchor an object to the org, by providing its hash in *multihash* format.
    /// This method should be used for adding new objects to the org, as well as
    /// updating existing ones.
    ///
    /// The `kind` paramter may be used to specify the kind of object being
    /// anchored. Defaults to `0`.
    function anchor(
        bytes32 id,
        bytes calldata multihash,
        uint8 kind
    ) public ownerOnly {
        anchors[id] = Anchor(multihash, kind);
        emit Anchored(id, multihash, kind);
    }

    /// Unanchor an object from the org.
    function unanchor(bytes32 id) public ownerOnly {
        delete anchors[id];
        emit Unanchored(id);
    }

    /// Transfer funds from this contract to the owner contract.
    function recoverFunds(IERC20 token, uint256 amount) public ownerOnly returns (bool) {
        return token.transfer(msg.sender, amount);
    }

    /// Configures the caller's reverse ENS record to point to the provided name.
    /// The address of the ENS registry is passed as the second parameter.
    function setName(string memory name, ENS ens) public ownerOnly returns (bytes32) {
        ReverseRegistrar registrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        bytes32 node = registrar.setName(name);
        emit NameChanged(name);

        return node;
    }
}
