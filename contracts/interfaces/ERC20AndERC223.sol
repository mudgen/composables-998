pragma solidity ^0.4.24;

interface ERC20AndERC223 {
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function transfer(address to, uint value) external returns (bool success);
  function transfer(address to, uint value, bytes data) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}