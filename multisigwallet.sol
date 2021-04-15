pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    address[] public owners;
    uint limit;
    uint balance;
    
    struct Transfer {
        address initiator;
        address payable recipient;
        uint amount;
        uint numApprovals;
        bool completed;
    }
    
    // Array of all transferRequests. The index is the transferID.
    Transfer[] transferRequests;
    
    // Double mapping of transferID to approver address to boolean approval status.
    mapping(uint => mapping(address => bool)) approvals;
    
    constructor() {
        owners = [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db];
        limit = 2;
    }
    
    modifier onlyOwner {
        // TODO how to efficiently check for value existence in array?
        require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2]);
        _;
    }
    
    /*
     * Any of the contract `owners` can deposit to the contract balance.
     */
    function deposit() public payable onlyOwner returns (uint) {
        balance += msg.value;
        return balance;
    }
    
    function transfer(address payable recipient, uint amount) public onlyOwner returns (uint) {
        recipient.transfer(amount);
        balance -= amount;
        return balance;
    }
    
    /*
     * Initiates a transfer request, with msg.sender as the initiator.
     */
    function withdraw(address payable recipient, uint amount) public onlyOwner returns (uint) {
        require(amount <= balance, "Insufficient balance");
        
        // Should the withdrawer count as an approver? Assume not.
        Transfer memory transferRequest = Transfer(msg.sender, recipient, amount, 0, false);
        transferRequests.push(transferRequest);
        uint transferID = transferRequests.length - 1;
        
        return transferID;
    }
    
    /*
     * Approves a transfer request. The initiator cannot be an approver, and `limit` number
     * of approvers are required. Once the number of approvers is satisfied, the transfer
     * is made.
     */
    function approve(uint transferID) public onlyOwner {
        require(msg.sender != transferRequests[transferID].initiator, "Initiator cannot be an approver");
        require(!approvals[transferID][msg.sender], "This owner has already approved this transfer");
        
        Transfer memory transferRequest = transferRequests[transferID];
        approvals[transferID][msg.sender] = true;
        transferRequest.numApprovals += 1;
        
        if (transferRequest.numApprovals >= limit) {
            transfer(transferRequest.recipient, transferRequest.amount);
            transferRequest.completed = true;
        }
    }
    
}