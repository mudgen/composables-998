pragma solidity ^0.4.24;

interface ERC998ERC721BottomUpEnumerableI {
  function totalChildTokens(address _parentContract, uint256 _parentTokenId) external view returns(uint256);
  function childTokenByIndex(address _parentContract, uint256 _parentTokenId, uint256 _index) external view returns(uint256);
}