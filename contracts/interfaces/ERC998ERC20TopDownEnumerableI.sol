pragma solidity ^0.4.24;

interface ERC998ERC20TopDownEnumerableI {
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256);
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address);
}