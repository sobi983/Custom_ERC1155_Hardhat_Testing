// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error AlreadyMinted();
error NotEqual();
error InvalidAddress();
error IdDoesnotExist();
error NoMoreItemForPurchase();

contract Exhibition is ERC1155, Ownable, Pausable, ERC1155Burnable {
    using Strings for string;
    using Address for address;
    
    constructor(string memory urii) ERC1155("") {
        setURI(urii);
    }
  
    string public baseURI;
    string public baseExtension = ".json";

    mapping (uint256 => bool) private _mintExists;
    mapping (uint => uint256) private _totalSupply;
    mapping (uint256 => mapping(uint256 => uint256)) public tokenExistPrice; //The owner will save the prices of the tokens after deployment, this will save the contract for further minting by the outsiders.
    mapping (uint256 => mapping(address => uint256)) private _balances;

    //This will be used to save the token ids, token quantities and the prices after the deployment by the owner.
    function saveTokens_Quantity_Prices(uint256[] memory tokenIds, uint256[] memory tokenQuantities, uint256[] memory tokenPrices) public onlyOwner{
       
        if(tokenIds.length != tokenQuantities.length && tokenQuantities.length != tokenPrices.length) revert NotEqual();
        for( uint i=0; i < tokenIds.length; ++i)
        tokenExistPrice[tokenIds[i]][tokenQuantities[i]] = tokenPrices[i];
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _setURI(string memory newuri) internal override {
        baseURI = newuri;
    }

    function uri(uint) public view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
     require(ID_exist(tokenId), "ERC721Metadata: URI query for nonexistent token");

     string memory currentBaseURI = baseURI;
     return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
    }

    function ID_exist(uint256 id) public view returns (bool) {
        return _mintExists[id];
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory){
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public payable whenNotPaused{
        
        require(msg.value >= tokenExistPrice[id][amount], "Minting Price Invalid number");  
        if(!ID_exist(id) && tokenExistPrice[id][amount] > 0){  //If the price of the token is zero then the tokens doesn't exist.
            _mint(account, id, amount, data);  
        }
        else{  //if the token exist
            purchase(id, account);
        }
    }

    function _mint( address to, uint256 id, uint256 amount, bytes memory data ) internal override  {
        require(to != address(0), "ERC1155: mint to the zero address");


        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArr(id);
        uint256[] memory amounts = _asSingletonArr(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _totalSupply[id] += amount;
        _mintExists[id] = true;

        _balances[id][to] += (amount-(amount - 1));
        _balances[id][address(this)] += (amount - 1);
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptance(operator, address(0), to, id, amount, data);
    }

    function purchase(uint256 id, address to) internal whenNotPaused{

        if(ID_exist(id)){
            transfer(to, id);
        }
        else{
            revert IdDoesnotExist();
        }
    }

    function transfer(address to, uint id) internal{
        if(to == address(0)) revert InvalidAddress();
        if(balanceOf(address(this), id) == 0) revert NoMoreItemForPurchase();
        _balances[id][to] += 1;
        _balances[id][address(this)] -= 1;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner whenNotPaused{
        _mintBatch(to, ids, amounts, data);
    }

    function _mintBatch( address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += (amounts[i] -(amounts[i] - 1));
            _balances[ids[i]][address(this)] += (amounts[i] - 1);
            _totalSupply[ids[i]] += amounts[i];
            _mintExists[ids[i]] = true;
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptance(operator, address(0), to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override{
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _asSingletonArr(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _doSafeTransferAcceptance(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) private  {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptance(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }
}