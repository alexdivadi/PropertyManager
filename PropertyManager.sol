// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;


// This is a smart contract by David Allen
// Created: 4/22/24
contract PropertyManager {
  struct Property {
    string name;
    uint256 rent;
    uint256 deposit;
    uint timestamp;
    uint256 lateFee;
  }

  address payable public landlord;
  Property[] public properties;
  address[] tenants;
  mapping(address => Property) rentals;
  uint256 private rentalIncome;

  event log(string message);

  constructor() payable  {
    landlord = payable(msg.sender);
  }

  function currentContractBalance() public view returns (uint) {
        return address(this).balance;
  }
  function listProperties() public view returns (Property[] memory) {
        return properties;
  }
  function listTenants() public view returns (address[] memory) {
        return tenants;
  }

  function removeTenant(address _tenantToRemove) private {
    for (uint i = 0; i < tenants.length; i++){
        if(tenants[i] == _tenantToRemove) {
            tenants[i] = tenants[tenants.length-1];
            tenants.pop();
            break;
        }
    }
}

  function addProperty(string memory name, uint256 rent, uint256 deposit) public {
    require(msg.sender == landlord);
    properties.push(Property(name, rent, deposit, block.timestamp, 0));
    emit log(string.concat("Property added: ", name));
  }

  function addTenantToProperty(address tenant, uint8 propertyIndex) public {
    require(msg.sender == landlord);
    require(propertyIndex < properties.length);
    properties[propertyIndex].timestamp =  block.timestamp;
    rentals[tenant] = properties[propertyIndex];
    tenants.push(tenant);
    emit log("Tenant added successfully.");
  }

  function paySecurityDeposit() public payable {
    require(msg.value > 0);
    require(msg.value == rentals[msg.sender].deposit);
    emit log("Security deposity paid successfully.");
  }

  function payRent() public payable {
    require(msg.value > 0);
    require(msg.value == rentals[msg.sender].rent + rentals[msg.sender].lateFee);
    rentals[msg.sender].lateFee = 0;
    rentals[msg.sender].timestamp = block.timestamp;
    rentalIncome += msg.value;
    emit log("Rent paid successfully.");
  }

  function withdrawRent() public payable {
    require(msg.sender == landlord);
    require(rentalIncome <= currentContractBalance());
    landlord.transfer(rentalIncome);
    rentalIncome = 0;
    emit log("Rent withdrawn successfully.");
  }

  function terminateLease(address tenant) public payable  {
    require(msg.sender == landlord);
    require(rentals[tenant].deposit <= currentContractBalance());
    payable(tenant).transfer(rentals[tenant].deposit);
    removeTenant(tenant);
    delete rentals[tenant];
    emit log("Lease terminated successfully.");
  }

  function chargeLateFee(address tenant) public {
    require(msg.sender == landlord);
    require(block.timestamp - rentals[tenant].timestamp > 60*60*24*30);
    rentals[tenant].lateFee = (block.timestamp 
                              - rentals[tenant].timestamp 
                              - 60*60*24*30) * 60 * 2 * 24 
                              * rentals[tenant].rent;
    emit log("Late fee added to rental property.");
  }

}
