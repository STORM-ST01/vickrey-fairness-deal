// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract VickreyAuction {
    address public immutable owner;
    address public oracle;
    uint256 public auctionCount;

    event OracleChanged(address indexed newOracle);

    struct Auction {
        uint256 startTime;
        uint256 endTime;
        uint256 revealEndTime;
        uint256 entregaDeadline;
        uint256 maxPrice;
        uint256 bidCount;
        bool finalized;
        bool entregaConfirmada;
        address winner;
        uint256 winningPrice;
        uint256 totalPayment;
    }

    struct BidCommit {
        bytes32 commitment;
        uint256 deposit;
        bool revealed;
        uint256 bidAmount;
        bool withdrawn;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => BidCommit)) public bids;
    mapping(uint256 => address[]) public bidders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar esto");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Solo el oracle puede confirmar");
        _;
    }

    modifier duringCommit(uint256 auctionId) {
        require(block.timestamp >= auctions[auctionId].startTime, "Subasta no iniciada");
        require(block.timestamp < auctions[auctionId].endTime, "Fase de pujas finalizada");
        _;
    }

    modifier duringReveal(uint256 auctionId) {
        require(block.timestamp >= auctions[auctionId].endTime, "Aun no es fase de revelacion");
        require(block.timestamp < auctions[auctionId].revealEndTime, "Fase de revelacion finalizada");
        _;
    }

    modifier onlyBeforeFinalize(uint256 auctionId) {
        require(!auctions[auctionId].finalized, "Subasta ya finalizada");
        _;
    }

    constructor() {
        owner = msg.sender;
        oracle = msg.sender;
    }

    function setOracle(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "Direccion invalida");
        oracle = oracleAddress;
        emit OracleChanged(oracleAddress);
    }

    function createAuction(
        uint256 startTime,
        uint256 endTime,
        uint256 revealEndTime,
        uint256 entregaDeadline,
        uint256 maxPrice
    ) public payable onlyOwner {
        require(startTime < endTime, "Tiempo de inicio debe ser antes del fin");
        require(endTime < revealEndTime, "Revelacion debe ser despues de la subasta");
        require(maxPrice > 0, "Precio maximo debe ser positivo");
        require(msg.value > 0, "Debes depositar ETH para pagar el suministro");

        auctions[auctionCount] = Auction({
            startTime: startTime,
            endTime: endTime,
            revealEndTime: revealEndTime,
            entregaDeadline: entregaDeadline,
            maxPrice: maxPrice,
            bidCount: 0,
            finalized: false,
            entregaConfirmada: false,
            winner: address(0),
            winningPrice: 0,
            totalPayment: msg.value
        });

        auctionCount++;
    }

    function commitBid(uint256 auctionId, bytes32 commitment) public payable duringCommit(auctionId) {
        require(bids[auctionId][msg.sender].commitment == 0, "Ya has pujado");
        require(commitment != 0, "Commitment invalido");

        bids[auctionId][msg.sender] = BidCommit({
            commitment: commitment,
            deposit: msg.value,
            revealed: false,
            bidAmount: 0,
            withdrawn: false
        });

        bidders[auctionId].push(msg.sender);
        auctions[auctionId].bidCount++;

        require(auctions[auctionId].bidCount <= 30, "Limite de pujas alcanzado");
    }

    function revealBid(uint256 auctionId, uint256 bidValue, string memory salt) public duringReveal(auctionId) {
        BidCommit storage bid = bids[auctionId][msg.sender];
        require(!bid.revealed, "Ya revelado");
        require(bid.commitment != 0, "No has pujado");
        require(
            keccak256(abi.encodePacked(bidValue, "|", salt)) == bid.commitment,
            "Hash no coincide"
        );
        require(bidValue > 0 && bidValue <= auctions[auctionId].maxPrice, "Puja fuera de rango");
        require(bid.deposit >= (bidValue * 10) / 100, "Deposito insuficiente");

        bid.revealed = true;
        bid.bidAmount = bidValue;
    }

    function finalizeAuction(uint256 auctionId) public onlyBeforeFinalize(auctionId) {
        require(block.timestamp >= auctions[auctionId].revealEndTime, "Fase de revelacion aun activa");

        Auction storage auction = auctions[auctionId];
        address lowestBidder = address(0);
        address secondLowestBidder;
        uint256 lowest = type(uint256).max;
        uint256 secondLowest = type(uint256).max;

        for (uint i = 0; i < bidders[auctionId].length; i++) {
            address addr = bidders[auctionId][i];
            BidCommit memory b = bids[auctionId][addr];
            if (!b.revealed) continue;

            if (b.bidAmount < lowest) {
                secondLowest = lowest;
                secondLowestBidder = lowestBidder;
                lowest = b.bidAmount;
                lowestBidder = addr;
            } else if (b.bidAmount < secondLowest) {
                secondLowest = b.bidAmount;
                secondLowestBidder = addr;
            }
        }

        require(lowest != type(uint256).max, "Nadie ha revelado");

        auction.winner = lowestBidder;
        auction.winningPrice = (secondLowest == type(uint256).max) ? lowest : secondLowest;
        auction.finalized = true;

        // Pago inmediato al ganador
        payable(auction.winner).transfer(auction.winningPrice);
    }

    function confirmarEntrega(uint256 auctionId) public onlyOracle {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp <= auction.entregaDeadline, "Entrega fuera de plazo");
        auction.entregaConfirmada = true;
    }

    function withdrawDeposit(uint256 auctionId) public {
        Auction storage auction = auctions[auctionId];
        BidCommit storage bid = bids[auctionId][msg.sender];
        require(auction.finalized, "Subasta no finalizada");
        require(bid.commitment != 0, "No participaste");
        require(!bid.withdrawn, "Ya retirado");

        uint256 refund = 0;

        if (msg.sender == auction.winner) {
            if (auction.entregaConfirmada) {
                refund = bid.deposit;
            }
        } else if (bid.revealed) {
            refund = bid.deposit;
        }

        bid.withdrawn = true;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function recuperarFondosNoUsados(uint256 auctionId) public onlyOwner {
        Auction storage auction = auctions[auctionId];
        require(auction.finalized, "Subasta no finalizada");
        require(block.timestamp > auction.entregaDeadline, "Plazo no vencido");

        if (!auction.entregaConfirmada) {
            payable(owner).transfer(auction.totalPayment - auction.winningPrice);
        }
    }
}
