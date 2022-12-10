// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GameContract {
    enum Status {
        WaitingForPlayers,
        WaitingForSecondPlayer,
        EnoughPlayers,
        FirstPlayerCommited,
        SecondPlayerCommited,
        FirstPlayerRevealed,
        SecondPlayerRevealed
    }

    enum Figure {
        None,
        Rock,
        Paper,
        Scissors
    }

    event StatusChanged(Status status);

    event WinnerFound(address winner);

    struct PlayersTurn {
        Figure figure;
        address playerAddress;
        bytes32 commitHash;
    }

    struct GameRound {
        PlayersTurn player1;
        PlayersTurn player2;
    }

    GameRound public gameRound;
    Status public status;
    bytes32 public hash;

    function setStatus(Status newStatus) private {
        status = newStatus;
        emit StatusChanged(newStatus);
    }

    function clear() private {
        setStatus(Status.WaitingForPlayers);
        gameRound.player1.figure = Figure.None;
        gameRound.player2.figure = Figure.None;
    }

    function joinPlayer() public {
        if (status == Status.WaitingForPlayers) {
            gameRound.player1.playerAddress = msg.sender;
            setStatus(Status.WaitingForSecondPlayer);
        }
        else if (status == Status.WaitingForSecondPlayer) {
            gameRound.player2.playerAddress = msg.sender;
            setStatus(Status.EnoughPlayers);
        }
        else {
            revert("the round has started");
        }
    }

    function commitMove(bytes32 hash) external {
        if (gameRound.player1.playerAddress == msg.sender) {
            gameRound.player1.commitHash = hash;
            setStatus(Status.FirstPlayerCommited);
        }
        else if (gameRound.player2.playerAddress == msg.sender) {
            gameRound.player2.commitHash = hash;
            setStatus(Status.SecondPlayerCommited);
        }
        else {
            revert("The address is not playing this round");
        }
    }
    
    function revealMove(uint256 moveId, string memory salt) external {
        hash = keccak256(abi.encodePacked(moveId, salt));

        if (gameRound.player1.playerAddress == msg.sender) {
            require(gameRound.player1.commitHash == hash, "hash isn't valid");

            gameRound.player1.figure = Figure(moveId);
            setStatus(Status.FirstPlayerRevealed);
        }
        else if (gameRound.player2.playerAddress == msg.sender) {
            require(gameRound.player2.commitHash == hash, "hash isn't valid");

            gameRound.player2.figure = Figure(moveId);
            setStatus(Status.SecondPlayerRevealed);
        }
        else {
            revert("the address of not one of the players");
        }
    }

    modifier gameContinuing() {
       require(gameRound.player1.figure == Figure.None 
        || gameRound.player2.figure == Figure.None,
         "round is continuing!");
        _;
    }

    function calculateWiner() gameContinuing external {
        if (gameRound.player1.figure == gameRound.player2.figure) {
            emit WinnerFound(address(0));
        }
        else if ((gameRound.player1.figure == Figure.Rock
             && gameRound.player1.figure == Figure.Scissors) ||
            (gameRound.player1.figure == Figure.Paper 
            && gameRound.player1.figure == Figure.Rock) ||
            (gameRound.player1.figure == Figure.Scissors
             && gameRound.player1.figure == Figure.Paper)) {
            emit WinnerFound(gameRound.player1.playerAddress);
        } 
        else {
            emit WinnerFound(gameRound.player2.playerAddress);
        }
        clear();
    }
}
