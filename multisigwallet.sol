pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    address[] owners;
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
    
    constructor(address[] memory _owners, uint _limit) {
        // ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
        owners = _owners;
        limit = _limit;
    }
    
    modifier onlyOwner {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
            }
        }
        require(isOwner, "Not an owner");
        _;
    }
    
    function getBalance() public view returns (uint) {
        return balance;
    }
    
    function getOwners() public view returns (address[] memory) {
        return owners;
    }
    
    function getTransfer(uint transferID) public view returns (Transfer memory) {
        return transferRequests[transferID];
    }
    
    /*
     * Any of the contract `owners` can deposit to the contract balance.
     * 
     * Returns new balance.
     */
    function deposit() public payable onlyOwner returns (uint) {
        balance += msg.value;
        return balance;
    }
    
    /*
     * Initiates a transfer request, with msg.sender as the initiator.
     * 
     * Returns transferID.
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
     *
     * Returns true if approved, false if more approvals required.
     */
    function approve(uint transferID) public onlyOwner returns (bool) {
        require(!transferRequests[transferID].completed, "Transfer has already been sent");
        require(msg.sender != transferRequests[transferID].initiator, "Initiator cannot be an approver");
        require(!approvals[transferID][msg.sender], "This owner has already approved this transfer");
        
        Transfer storage transferRequest = transferRequests[transferID];
        approvals[transferID][msg.sender] = true;
        transferRequest.numApprovals += 1;
        
        if (transferRequest.numApprovals >= limit) {
            transfer(transferRequest.recipient, transferRequest.amount);
            transferRequest.completed = true;
            return true;
        }
        
        return false;
    }
    
    function transfer(address payable recipient, uint amount) private returns (uint) {
        recipient.transfer(amount);
        balance -= amount;
        return balance;
    }
    
}