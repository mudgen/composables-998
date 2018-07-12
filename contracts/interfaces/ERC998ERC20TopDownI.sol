pragma solidity ^0.4.24;

interface ERC998ERC20TopDownI {
  event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc223Contract, uint256 _value);
  event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc223Contract, uint256 _value);

  function tokenFallback(address _from, uint256 _value, bytes _data) external;
  function balanceOfERC20(uint256 _tokenId, address __erc223Contract) external view returns(uint256);
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external;
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external;
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) external;

}