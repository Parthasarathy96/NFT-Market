pragma solidity ^0.5.4;

import "./IERC721.sol";
import "./IERC20.sol";

contract NFTMarket{

    string public name = "NFT Market";

    uint public auctionCount;

    mapping(uint256 => auction) public MarketItemID;
    enum NFTStatus{OPEN,UNPAID, UNSOLD, SOLD}

    struct auction{
        uint256 Id;
        address NFTContractAddress;
        address tokenAddress;
        uint256 nftID;
        address seller;
        address payable highestBidder;
        uint256 currentPrice;
        uint256 deadline;
        uint256 bidCount;
        NFTStatus status;
    } 
    auction[] public Auctions;
    
    event newBid(uint256 _auctionId, uint256 amount);
    event NFTClaimed(uint256 _auctionId, uint256 nftId, address claimedBy);
    event TokensClaimed(uint256 _auctionId, uint256 nftId, address claimedBy);
    event NFTRefunded(uint256 _auctionId, uint256 nftId, address claimedBy);

//Checks if the address is Contract
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

//User can create auction.

    function CreateAuction(address _NFTcontract, address _paymentToken, uint256 _tokenID, uint256 _initialBid, uint256 _endAuction) external returns(uint256){

        require(isContract(_NFTcontract), "Invalid NFT address");

        require(isContract(_paymentToken), "Invalid Payment Token Address");

        require(_endAuction > block.timestamp, "Invalid end date");

        require(_initialBid > 0, "Invalid initial bid price");

        require(IERC721(_NFTcontract).ownerOf(_tokenID) == msg.sender,"Caller is not the owner of the NFT");

        require(IERC721(_NFTcontract).getApproved(_tokenID) == address(this), "NFT must be approved to market");

        IERC721(_NFTcontract).transferFrom(msg.sender, address(this), _tokenID);

        auction memory newAuction = auction(
            auctionCount,
            _NFTcontract,
            _paymentToken,   
            _tokenID,
            msg.sender,
            address(0),
            _initialBid,
            _endAuction,
            0,
            NFTStatus.OPEN
    );  
    MarketItemID[_tokenID] = newAuction;
        Auctions.push(newAuction);
        auctionCount += 1; 
    }


//User can bid in the auction
    function bid(uint _auctionId, uint _amount) external  returns(bool bidStatus){
    auction memory Auction = MarketItemID[_auctionId];
    IERC20 paymentToken = IERC20(Auction.tokenAddress);

    require(Auction.status == NFTStatus.OPEN, "Auction is not open");

    require(Auction.seller != msg.sender, "The seller cannot bid");

    require(_amount > Auction.currentPrice, "The new bid must be higher than the old bid");

    require(IERC20(Auction.tokenAddress).allowance(msg.sender ,address(this)) >= _amount, "Approve more amount");

    require(paymentToken.transferFrom(msg.sender, address(this), _amount), "Tranfer of token failed");

    if (Auction.bidCount > 0) {
            paymentToken.transfer(
                Auction.highestBidder,
                Auction.currentPrice
            );
        }
    MarketItemID[_auctionId].highestBidder = msg.sender;
    MarketItemID[_auctionId].currentPrice = _amount;
    MarketItemID[_auctionId].bidCount += 1;

    emit newBid(_auctionId, _amount);
    
    return true;
}


//The Bid winner can claim the NFT
    function claimNFT(uint256 _auctionId) external{
    require(MarketItemID[_auctionId].status != NFTStatus.OPEN, "Auction is still open");

    auction storage Auction = MarketItemID[_auctionId];

    require(Auction.highestBidder == msg.sender, "NFT can only claimed by the highest bidder");

    IERC721(Auction.NFTContractAddress).safeTransferFrom(address(this), Auction.highestBidder, Auction.nftID);

    Auction.status = NFTStatus.SOLD;
    
    emit NFTClaimed(_auctionId, Auction.nftID, msg.sender);
}

//Check the status of the auction
function checkAuction(uint256 _auctionId) public view returns(NFTStatus _status) {

    auction memory Auction = MarketItemID[_auctionId];

    if(block.timestamp >= Auction.deadline){
        Auction.status = NFTStatus.UNSOLD;
    }
    return Auction.status;
}


//The seller can claim the Tokens
    function claimToken(uint256 _auctionId) external {
        require(_auctionId < Auctions.length, "Invalid auction index"); 

        require(checkAuction(_auctionId)!= NFTStatus.OPEN, "Auction is still open");

        auction memory Auction = Auctions[_auctionId];

        require(Auction.seller == msg.sender, "Tokens can be claimed only by the creator of the auction");

        IERC20 paymentToken = IERC20(Auction.tokenAddress);

        paymentToken.transfer(Auction.seller, Auction.currentPrice);

    emit TokensClaimed(_auctionId, Auction.nftID, msg.sender);
    }

//The Seller can get back his/her NFT
    function refund(uint256 _auctionId) external{

        require(_auctionId < Auctions.length, "Invalid auction index");

        require(checkAuction(_auctionId)!= NFTStatus.OPEN, "Auction is still open");

        auction storage Auction = MarketItemID[_auctionId];

        require(Auction.seller == msg.sender, "Tokens can be claimed only by the creator of the auction");

        require(Auction.highestBidder == address(0), "Existing bider for this auction");

        IERC721 nftCollection = IERC721(Auction.NFTContractAddress);

        nftCollection.transferFrom(address(this), Auction.seller, Auction.nftID );

        emit NFTRefunded(_auctionId, Auction.nftID, msg.sender);
    }

//The users can get the highest bidder.
    function highestBidder(uint256 _auctionId) public view returns(address, uint256){

        require(_auctionId < Auctions.length, "Invalid auction index");

        auction memory Auction = MarketItemID[_auctionId];

        return (Auction.highestBidder, Auction.currentPrice);
    }
}

