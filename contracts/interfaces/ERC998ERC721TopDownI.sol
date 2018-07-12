pragma solidity ^0.4.24;

interface ERC998ERC721TopDownI {
  event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
  event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);


  // gets the address and token that owns the supplied tokenId. isParent says if parentTokenId is a parent token or not.
  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4);
  function onERC998Removed(uint256 _childTokenId) external;
  function transferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
  // getChild function enables older contracts like cryptokitties to be transferred into a composable
  // The _childContract must approve this contract. Then getChild can be called.
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}