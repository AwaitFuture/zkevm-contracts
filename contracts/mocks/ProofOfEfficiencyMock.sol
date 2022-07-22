// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import "../ProofOfEfficiency.sol";
import "hardhat/console.sol";

/**
 * Contract responsible for managing the state and the updates of it of the L2 Hermez network.
 * There will be sequencer, wich are able to send transactions. That transactions will be stored in the contract.
 * The aggregators are forced to process and validate the sequencers transactions in the same order by using a verifier.
 * To enter and exit of the L2 network will be used a Bridge smart contract
 */
contract ProofOfEfficiencyMock is ProofOfEfficiency {
    /**
     * @param _globalExitRootManager Global exit root manager address
     * @param _matic MATIC token address
     * @param _rollupVerifier rollup verifier address
     * @param genesisRoot rollup genesis root
     */
    constructor(
        IGlobalExitRootManager _globalExitRootManager,
        IERC20 _matic,
        IVerifierRollup _rollupVerifier,
        bytes32 genesisRoot
    )
        ProofOfEfficiency(
            _globalExitRootManager,
            _matic,
            _rollupVerifier,
            genesisRoot
        )
    {}

    /**
     * @notice Calculate the circuit input
     * @param currentStateRoot Current state Root
     * @param currentLocalExitRoot Current local exit root
     * @param newStateRoot New State root once the batch is processed
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param batchHashData Batch hash data
     */
    function calculateCircuitInput(
        bytes32 currentStateRoot,
        bytes32 currentLocalExitRoot,
        bytes32 newStateRoot,
        bytes32 newLocalExitRoot,
        bytes32 batchHashData
    ) public pure returns (uint256) {
        uint256 input = uint256(
            keccak256(
                abi.encodePacked(
                    currentStateRoot,
                    currentLocalExitRoot,
                    newStateRoot,
                    newLocalExitRoot,
                    batchHashData
                )
            )
        ) % _RFIELD;
        return input;
    }

    /**
     * @notice Calculate the circuit input
     * @param newStateRoot New State root once the batch is processed
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param numBatch Batch number that the aggregator intends to verify, used as a sanity check
     */
    function getNextCircuitInput(
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        uint32 numBatch
    ) public view returns (uint256) {
        // sanity check
        require(
            numBatch == lastVerifiedBatch + 1,
            "ProofOfEfficiency::verifyBatch: BATCH_DOES_NOT_MATCH"
        );

        // Calculate Circuit Input
        BatchData memory currentBatch = sentBatches[numBatch];

        uint256 input = uint256(
            keccak256(
                abi.encodePacked(
                    currentStateRoot,
                    currentLocalExitRoot,
                    newStateRoot,
                    newLocalExitRoot,
                    currentBatch.batchHashData
                )
            )
        ) % _RFIELD;
        return input;
    }

    /**
     * @notice Return the input hash parameters
     * @param newStateRoot New State root once the batch is processed
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param numBatch Batch number that the aggregator intends to verify, used as a sanity check
     */
    function returnInputHashParameters(
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        uint32 numBatch
    ) public view returns (bytes memory) {
        // sanity check
        require(
            numBatch == lastVerifiedBatch + 1,
            "ProofOfEfficiency::verifyBatch: BATCH_DOES_NOT_MATCH"
        );

        // Calculate Circuit Input
        BatchData memory currentBatch = sentBatches[numBatch];

        return
            abi.encodePacked(
                currentStateRoot,
                currentLocalExitRoot,
                newStateRoot,
                newLocalExitRoot,
                currentBatch.batchHashData
            );
    }

    /**
     * @notice Set state root
     * @param newStateRoot New State root ¡
     */
    function setStateRoot(bytes32 newStateRoot) public onlyOwner {
        currentStateRoot = newStateRoot;
    }

    /**
     * @notice Set Sequencer
     * @param newLocalExitRoot New exit root ¡
     */
    function setExitRoot(bytes32 newLocalExitRoot) public onlyOwner {
        currentLocalExitRoot = newLocalExitRoot;
    }

    /**
     * @notice Allows to register a new sequencer or update the sequencer URL
     * @param sequencerURL sequencer RPC URL
     */
    function setSequencer(
        address sequencer,
        string memory sequencerURL,
        uint32 chainID
    ) public onlyOwner {
        sequencers[sequencer].sequencerURL = sequencerURL;
        sequencers[sequencer].chainID = chainID;
    }

    /**
     * @notice VerifyBatchMock
     */
    function verifyBatchMock() public onlyOwner {
        // Update state
        lastVerifiedBatch++;
        // Interact with bridge
        globalExitRootManager.updateExitRoot(currentLocalExitRoot);
        emit VerifyBatch(lastVerifiedBatch, msg.sender);
    }

    /**
     * @notice Allows to set Batch
     */
    function setBatch(
        bytes32 batchHashData,
        uint256 maticCollateral,
        uint32 batchNum
    ) public onlyOwner {
        sentBatches[batchNum].batchHashData = batchHashData;
        sentBatches[batchNum].maticCollateral = maticCollateral;
    }
}
