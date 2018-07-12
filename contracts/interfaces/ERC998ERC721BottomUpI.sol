pragma solidity ^0.4.24;

interface ERC998ERC721BottomUpI{

  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 _tokenId);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 _tokenId);
  // Transfers _tokenId as a child to _toContract and _toTokenId
  function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId) external;
  // Transfers _tokenId from a parent ERC721 token to a user address.
  function transferFromParent(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId, bytes _data) external;
  // Transfers _tokenId from a parent ERC721 token to a parent ERC721 token.
  function transferAsChild(address _fromContract, uint256 _fromTokenId, address _toContract, uint256 _toTokenId, uint256 _tokenId) external;
}