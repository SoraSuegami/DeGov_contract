pragma solidity >=0.5.0;

import "openzeppelin-solidity/contracts/drafts/Counters.sol";

contract DelegatedGovernment {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address[] public members;
    Counters.Counter private members_number = Counters.Counter(0);
    address public parent;
    address[] public children;
    Counters.Counter private children_number = Counters.Counter(0);
    mapping(bytes32=>address) public authorities;

    mapping(address=>uint256) public budgets;
    uint256 public assigned_balance;

    modifier onlyParent {
        require(msg.sender==parent,"this function can be called only by parent");
        _;
    }

    constructor() public {
        parent = msg.sender;
    }

    function register_member(address new_member) public onlyParent {
        members.push(new_member);
        members_number.increment();
    }

    function dismiss_member(uint256 member_index) public onlyParent {
        require(_isMember(member_index),"the member does not exist");
        members[member_index] = address(0);
        members_number.decrement();
    }

    function generate_child(address child) public {
        children.push(child);
        children_number.increment();
    }

    function abolish_child(uint256 child_index) public {
        require(_isChild(child_index),"the child does not exist");
        children[child_index] = address(0);
        children_number.decrement();
    }

    function add_authority(bytes32 variable_id) public {
        require(authorities[variable_id]==address(0),"the variable already exists");
        authorities[variable_id] = address(this);
    }

    function delegate_authority(bytes32 variable_id, address new_administrator) public {
        require(_isAdministrator(variable_id),"this function can be called only by current administrator");
        authorities[variable_id] = new_administrator;
    }

    function deprive_authority(bytes32 variable_id) public {
        authorities[variable_id] = address(this);
    }

    function assign_budget(uint128 child_index, uint256 amount) public {
        require(_isChild(child_index),"the child does not exist");
        uint256 current_balance = address(this).balance;
        uint256 unassigned_balance = SafeMath.sub(current_balance,assigned_balance);
        require(SafeMath.sub(unassigned_balance,amount)>=0,"the amount is larger than unassigned balance");
        assigned_balance = SafeMath.add(assigned_balance,amount);
        address child = children[child_index];
        budgets[child] = SafeMath.add(budgets[child],amount);
    }

    function release_child_budget(uint128 child_index) public {
        require(_isChild(child_index),"the child does not exist");
        address payable child = address(uint160(children[child_index]));
        require(msg.sender==child,"only child can withdraw the budget");
        uint256 amount = budgets[child];
        budgets[child] = 0;
        assigned_balance = SafeMath.sub(assigned_balance,amount);
        msg.sender.transfer(amount);
    }

    function _isMember(uint256 member_index) private view returns(bool) {
        return member_index<members_number.current() && members[member_index]!=address(0);
    }

    function _isChild(uint child_index) private view returns(bool) {
        return child_index<children_number.current() && children[child_index]!=address(0);
    }

    function _isAdministrator(bytes32 variable_id) private view returns(bool) {
        return authorities[variable_id]!=address(0) && authorities[variable_id] == msg.sender;
    }

    function () payable external {
        require(msg.data.length == 0);
    }
}
