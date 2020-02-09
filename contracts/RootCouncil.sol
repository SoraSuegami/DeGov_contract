pragma solidity >=0.5.0;

import {DelegatedGovernment} from "./DelegatedGovernment.sol";

contract RootCouncil is DelegatedGovernment(address(0)) {
    struct Proposal {
        bytes32 id;
        string uri;
        address proposer;
        bool exist;
    }

    mapping (bytes32=>Proposal) public proposals;

    // state 1: the proposal is neither approvaled nor rejected.
    // state 2: the proposal is approvaled by the council.
    // state 3: the proposal is rejected by the government.
    mapping (bytes32=>uint8) public state_of_proposal;

    address government = address(0);
    address selector = address(0);
    bytes32 evidence_id = bytes32(0);

    bytes32 constant proposals_id = keccak256("proposals");
    bytes32 constant state_of_proposal_id = keccak256("state_of_proposal");
    bytes32 constant government_id = keccak256("government");
    bytes32 constant selector_id = keccak256("selector");
    bytes32 constant evidence_id_id = keccak256("evidence_id");

    modifier onlyGovernment {
        require(msg.sender==government,"this function can be calld only by the government");
        _;
    }

    modifier onlyApprovaled() {
        require(evidence_id!=bytes32(0),"zero bytes is invalid");
        require(proposals[evidence_id].exist==true && state_of_proposal[evidence_id]==1,"the proposal is not approvaled");
        add_authority(proposals_id);
        add_authority(state_of_proposal_id);
        add_authority(government_id);
        add_authority(selector_id);
        add_authority(evidence_id_id);
        delegate_authority(proposals_id, 0, selector);
        delegate_authority(state_of_proposal_id, 1, selector);
        _;
    }

    constructor(address _government, address _selector) public {
        government = _government;
        selector = _selector;
    }

    function set_evidence(bytes32 id) public {
        evidence_id = id;
    }

    function add_proposal(string memory uri) public onlyMember(msg.sender) {
        address proposer = msg.sender;
        bytes32 id = keccak256(abi.encode(uri,proposer));
        Proposal memory new_proposal = Proposal(id,uri,proposer,true);
        proposals[id] = new_proposal;
        state_of_proposal[id] = 1;
    }

    function reject_proposal(bytes32 id) public onlyAdministrator(msg.sender,proposals_id) {
        require(id!=bytes32(0),"zero bytes is invalid");
        require(proposals[id].exist==true,"the proposal does not exist");
        require(state_of_proposal[id]==1,"the proposal does not exist or it is already rejected");
        proposals[id].exist = false;
        state_of_proposal[id] = 3;
    }

    function register_member(address new_member) public onlyGovernment {
        super.register_member(new_member);
    }

    function dismiss_member(address member) public onlyGovernment {
        super.dismiss_member(member);
    }

    function add_child(address child) public onlyApprovaled {
        super.add_child(child);
    }

    function abolish_child(address child) public onlyApprovaled{
        super.abolish_child(child);
    }

    function add_authority(bytes32 variable_id) public onlyApprovaled {
        super.add_authority(variable_id);
    }

    function delegate_authority(bytes32 variable_id, uint256 variable_index, address new_administrator) public onlyApprovaled {
        super.delegate_authority(variable_id,variable_index,new_administrator);
    }

    function deprive_authority(bytes32 variable_id, uint256 variable_index) public onlyApprovaled {
        super.deprive_authority(variable_id,variable_index);
    }

    function assign_budget(address child, uint256 amount) public onlyApprovaled {
        super.assign_budget(child,amount);
    }

    function release_child_budget(address payable child) public onlyApprovaled {
        super.release_child_budget(child);
    }

    function isApprovaled(bytes32 id) public view returns(bool) {
        return id!=bytes32(0) && proposals[id].exist==true && state_of_proposal[id]==2;
    }
}