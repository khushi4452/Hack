
pragma solidity ^0.8.19;

contract FlightInsurance {
    address public owner;
    uint public insurancePrice = 0.01 ether; 
    uint public payoutAmount = 0.02 ether;   
    struct Policy {
        address user;
        string flightNumber;
        uint256 departureTime;
        bool isClaimed;
    }

    mapping(address => Policy) public policies;

    event InsuranceBought(address indexed user, string flightNumber, uint256 departureTime);
    event PayoutReleased(address indexed user, uint amount);
    event PayoutFailed(address indexed user, uint amount); 
    constructor() {
        owner = msg.sender;
    }

    
    function buyInsurance(string memory flightNumber, uint256 departureTime) external payable {
        require(msg.value == insurancePrice, "Incorrect amount sent");
        require(policies[msg.sender].departureTime == 0, "Already bought insurance");

        policies[msg.sender] = Policy(msg.sender, flightNumber, departureTime, false);
        emit InsuranceBought(msg.sender, flightNumber, departureTime);
    }

   
    function getPolicyDetails(address user) external view returns (string memory flightNumber, uint256 departureTime, bool isClaimed) {
        Policy storage policy = policies[user];
        return (policy.flightNumber, policy.departureTime, policy.isClaimed);
    }

   
    function claimPayout(bool isFlightDelayed) external {
        Policy storage policy = policies[msg.sender];
        require(policy.departureTime > 0, "No insurance found");
        require(!policy.isClaimed, "Already claimed");

        if (isFlightDelayed) {
            policy.isClaimed = true;
            (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
            
            if (success) {
                emit PayoutReleased(msg.sender, payoutAmount);
            } else {
                policy.isClaimed = false; // Revert claim if payout fails
                emit PayoutFailed(msg.sender, payoutAmount); 
            }
        }
    }

   
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

 
    receive() external payable {}


    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}
