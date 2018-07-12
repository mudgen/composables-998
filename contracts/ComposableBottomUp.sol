/**********************************
/* Author: Nick Mudge, <nick@perfectabstractions.com>, https://medium.com/@mudgen.
/**********************************/

pragma solidity ^0.4.24;

import "./ERC998ERC721BottomUpEnumerable.sol";
  /**
  * In a bottom-up composable authentication to transfer etc. is done by getting the rootOwner by finding the parent token
  * and then the parent token of that one until a final owner address is found.  If the msg.sender is the rootOwner or is
  * approved by the rootOwner then msg.sender is authenticated and the action can occur.
  * This enables the owner of the top-most parent of a tree of composables to call any method on child composables.
  */
contract ComposableBottomUp is ERC998ERC721BottomUpEnumerable {}