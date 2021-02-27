// /* Copyright (C) 2019

//   This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.

//   This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//     along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "./external/openzeppelin-solidity/token/ERC20/IERC20.sol";
import "./external/openzeppelin-solidity/token/ERC721/IERC721.sol";

contract Exchange  {



    enum Status {Initiated, Success, Withdrawn}
    // enum Type {ERC20ToERC20, ERC20ToERC721, ERC721ToERC20, ERC721ToERC721}

    struct ExchangeData {
        address party1;
        address party2;
        address token1;
        address token2;
        uint tokenID;
        uint amount2OrTokenID;
        uint expiry; // Time in seconds after which the transaction can be automatically executed if not disputed.
        bool party2Confirmation; // Last interaction for the dispute procedure.
        Status status;
    }


    // mapping(uint => IERC20) tokenInstance;


    ExchangeData[] public exchange;


    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _exchangeID The index of the exchange.
     *  @param _party1 1st party in exchange.
     *  @param _token1 The token address.
     *  @param _amount1 The amount of tokens/ Id of token in this transaction.
     *  @param _token2 The token address.
     *  @param _amount2 The amount of tokens/ Id of token in this transaction.
     */
    event ExchangeCreated(uint _exchangeID, address indexed _party1, address _token1, uint _amount1, address _token2, uint _amount2);

    event ExchangeStatusChange(uint _exchangeID, uint _status);

    /** @dev Create a exchange Entity to Entity. UNTRUSTED.
     *  @param _tokenId The amount of tokens/ Id of token in this transaction.
     *  @param _token1 The token address.
     *  @param _expiry Time after which a deal will off.
     *  @param _token2 The token address.
     *  @param _amount2OrTokenId The amount of tokens/ Id of token expecting.
     *  @return The index of the transaction.
     */
    function createExchange(
        uint _tokenId,
        address _token1,
        uint _expiry,
        address _token2,
        uint _amount2OrTokenId
    ) public returns (uint exchangeIndex) {
        IERC721 senderToken = IERC721(_token1); // both ERC20 and ERC721 have same signature for transfer and transferFrom.
        // Transfers token from sender wallet to contract.
        
        require(senderToken.transferFrom(msg.sender, address(this), _tokenId), "Sender does not have enough approved funds.");
        exchangeIndex = exchange.length;
        exchange.push(ExchangeData({
            party1: msg.sender,
            party2: address(0),
            token1: _token1,
            token2: _token2,
            tokenID: _tokenId,
            amount2OrTokenID: _amount2OrTokenId,
            expiry: now + _expiry,
            party2Confirmation: false,
            status: Status.Initiated
        }));
        
        emit ExchangeCreated(exchangeIndex, msg.sender, _token1, _tokenId, _token2, _amount2OrTokenId);
        emit ExchangeStatusChange(exchangeIndex, uint(Status.Initiated));

    }

    /** @dev party2 response for exchange.
     *  @param _exchangeID The index of the exchange.
     */
    function party2Response(uint _exchangeID) public {
        ExchangeData storage exchangeData = exchange[_exchangeID];
        require(exchangeData.status == Status.Initiated);
        require(exchangeData.expiry > now);
        IERC721 senderToken = IERC721(exchangeData.token1); // both ERC20 and ERC721 have same signature for transfer and transferFrom.

        IERC20 party2Token = IERC20(exchangeData.token2); // both ERC20 and ERC721 have same signature for transfer and transferFrom.
        require(senderToken.transfer(msg.sender, exchangeData.tokenID), "Transfer to party2 failed.");
        require(party2Token.transferFrom(msg.sender, exchangeData.party1, exchangeData.amount2OrTokenID), "party2 does not have enough approved funds.");
        exchangeData.party2 == msg.sender;
        
        exchange[_exchangeID].status = Status.Success;
        exchange[_exchangeID].party2Confirmation = true;
        emit ExchangeStatusChange(_exchangeID, uint(Status.Success));

        
    }

    /** @dev party one can withdraw anytime if status is still initiated.
     *  @param _exchangeID The index of the transaction.
     */
    function withdrawRequest(uint _exchangeID) public {
        ExchangeData storage exchangeData = exchange[_exchangeID];
        require(exchangeData.party1 == msg.sender);
        require(exchangeData.status == Status.Initiated);

        IERC721 senderToken = IERC721(exchangeData.token1);   // both ERC20 and ERC721 have same signature for transfer and transferFrom.
        
        require(senderToken.transfer(msg.sender, exchangeData.tokenID), "Transfer to party1 failed.");
        exchange[_exchangeID].status = Status.Withdrawn;
        emit ExchangeStatusChange(_exchangeID, uint(Status.Withdrawn));
    }


    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter to know the count of Exchange.
     *  @return count The count of exchanges.
     */
    function getCountExchange() public view returns (uint count) {
        return exchange.length;
    }

    // /** @dev Get IDs for transactions where the specified address is the receiver and/or the sender.
    //  *  This function must be used by the UI and not by other smart contracts.
    //  *  Note that the complexity is O(t), where t is amount of arbitrable transactions.
    //  *  @param _address The specified address.
    //  *  @return exchangeIDs The exchange IDs.
    //  */
    // function getExchangeIDsByAddress(address _address) public view returns (uint[] memory exchangeIDs) {
    //     uint count = 0;
    //     for (uint i = 0; i < exchange.length; i++) {
    //         if (exchange[i].party1 == _address || exchange[i].party2 == _address)
    //             count++;
    //     }

    //     exchangeIDs = new uint[](count);

    //     count = 0;

    //     for (uint j = 0; j < exchange.length; j++) {
    //         if (exchange[j].party1 == _address || exchange[j].party2 == _address)
    //             exchangeIDs[count++] = j;
    //     }
    // }
}

    

