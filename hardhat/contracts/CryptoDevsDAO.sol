// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketPlace {
    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        YEY,
        NEY
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketPlace nftMarketPlace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketPlace, address _cryptoDevsNFT) payable {
        nftMarketPlace = IFakeNFTMarketPlace(_nftMarketPlace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NFT_A_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalId) {
        require(
            proposals[proposalId].deadline > block.timestamp,
            "PROPOSAL_INACTIVE"
        );
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalId) {
        require(
            proposals[proposalId].deadline <= block.timestamp,
            "PROPOSAL_ACTIVE"
        );
        require(proposals[proposalId].executed == false, "ALREADY_EXECUTED");
        _;
    }

    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(nftMarketPlace.available(_nftTokenId), "NFT_NOT_FOR_SALE");

        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    function voteOnProposal(
        uint256 proposalId,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        uint256 voterNFTBalace = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes;

        for (uint256 i = 0; i < voterNFTBalace; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YEY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal(
        uint256 proposalId
    ) external nftHolderOnly inactiveProposalOnly(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketPlace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketPlace.purchase{value: nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    function withDrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
