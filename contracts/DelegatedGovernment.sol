pragma solidity >=0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/Counters.sol";

contract DelegatedGovernment {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address[] internal members;
    mapping (address=>uint256) internal index_of_member;
    Counters.Counter private members_number = Counters.Counter(0);
    address internal parent;
    address[] internal children;
    mapping (address=>uint256) internal index_of_child;
    Counters.Counter private children_number = Counters.Counter(0);
    mapping(bytes32=>address) internal administrator_of_variable;
    mapping(address=>bytes32[]) internal variables_of_administrator;
    mapping(address=>uint256) internal budgets;
    uint256 internal assigned_balance;

    /*modifier onlyParent {
        require(msg.sender==parent,"this function can be called only by parent");
        _;
    }*/

    modifier onlyMember(address member) {
        require(member!=address(0),"zero address is invalid");
        require(index_of_member[member]!=0,"the member does not exist");
        _;
    }

    modifier onlyChild(address child) {
        require(child!=address(0),"zero address is invalid");
        require(index_of_child[child] != 0,"the child does not exist");
        _;
    }

    modifier onlyAdministrator(address administrator, bytes32 variable_id) {
        require(administrator_of_variable[variable_id]!=address(0),"zero address is invalid");
        require(administrator_of_variable[variable_id]==administrator,"the administrator does not exist");
        _;
    }

    modifier onlyAuthorized(address administrator, bytes32 variable_id, uint256 variable_index) {
        require(administrator!=address(0),"zero address is invalid");
        require(variables_of_administrator[administrator][variable_index]==variable_id,"the variable_index does not specify the variable_id");
        require(administrator_of_variable[variable_id]==administrator,"the administrator does not exist");
        _;
    }

    constructor(address _parent) public {
        parent = _parent;
    }

    function register_member(address new_member) public {
        require(new_member!=address(0),"zero address is invalid");
        uint256 index = members.push(new_member);
        index_of_member[new_member] = index;
        members_number.increment();
    }

    function dismiss_member(address member) public onlyMember(member) {
        uint256 index = index_of_member[member];
        members[index] = address(0);
        index_of_member[member] = 0;
        members_number.decrement();
    }

    function add_child(address child) public {
        require(child!=address(0),"zero address is invalid");
        uint256 index = children.push(child);
        index_of_child[child] = index;
        children_number.increment();
    }

    function abolish_child(address child) public onlyChild(child){
        uint256 index = index_of_child[child];
        children[index] = address(0);
        index_of_child[child] = 0;
        children_number.decrement();
        uint256 budget = budgets[child];
        budgets[child] = 0;
        SafeMath.sub(assigned_balance,budget);
        bytes32[] memory variables = variables_of_administrator[child];
        uint len = variables.length;
        uint i;
        for(i=0;i<len;i++){
            bytes32 variable_id = variables[i];
            if(variable_id==bytes32(0)) continue;
            _deprive_authority(child,variable_id,i);
        }
    }

    function add_authority(bytes32 variable_id) public {
        require(variable_id!=bytes32(0),"zero bytes is invalid");
        require(administrator_of_variable[variable_id]==address(0),"the variable already exists");
        administrator_of_variable[variable_id] = address(this);
        variables_of_administrator[address(this)].push(variable_id);
    }

    function delegate_authority(bytes32 variable_id, uint256 variable_index, address new_administrator) public onlyAuthorized(msg.sender,variable_id,variable_index) {
        require(variable_id!=bytes32(0),"zero bytes is invalid");
        administrator_of_variable[variable_id] = new_administrator;
        variables_of_administrator[new_administrator].push(variable_id);
    }

    function deprive_authority(bytes32 variable_id, uint256 variable_index) public {
        _deprive_authority(msg.sender,variable_id,variable_index);
    }

    function _deprive_authority(address administrator, bytes32 variable_id, uint256 variable_index) public onlyAuthorized(administrator,variable_id,variable_index) {
        require(variable_id!=bytes32(0),"zero bytes is invalid");
        administrator_of_variable[variable_id] = address(this);
        variables_of_administrator[administrator][variable_index] = bytes32(0);
    }

    function assign_budget(address child, uint256 amount) public onlyChild(child) {
        uint256 current_balance = address(this).balance;
        uint256 unassigned_balance = SafeMath.sub(current_balance,assigned_balance);
        require(SafeMath.sub(unassigned_balance,amount)>=0,"the amount is larger than unassigned balance");
        assigned_balance = SafeMath.add(assigned_balance,amount);
        budgets[child] = SafeMath.add(budgets[child],amount);
    }

    function release_child_budget(address payable child) public onlyChild(child) {
        require(msg.sender==child,"only child can withdraw the budget");
        uint256 amount = budgets[child];
        budgets[child] = 0;
        assigned_balance = SafeMath.sub(assigned_balance,amount);
        msg.sender.transfer(amount);
    }

    function () payable external {
        require(msg.data.length == 0);
    }
}
