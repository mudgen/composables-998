pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC20TopDownEnumerableI.sol";
import "./ERC998ERC20TopDown.sol";

contract ERC998ERC20TopDownEnumerable is ERC998ERC20TopDownEnumerableI, ERC998ERC20TopDown {
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address) {
    require(_index < erc223Contracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return erc223Contracts[_tokenId][_index];
  }
  
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256) {
    return erc223Contracts[_tokenId].length;
  }
}

