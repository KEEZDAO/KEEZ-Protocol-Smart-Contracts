// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// IERC725Y
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

// Deployers
import {IDaoDeployer} from "./DaoDeployer/IDaoDeployer.sol";
import {IMultisigDeployer} from "./IMultisigDeployer.sol";
import {IUniversalProfileDeployer} from "./IUniversalProfileDeployer.sol";

contract Deployer {
  /**
   * @dev Dao deployer address
   */
  address private DAO_DEPLOYER;
  /**
   * @dev Multisig deployer address
   */
  address private MULTISIG_DEPLOYER;
  /**
   * @dev Universal Profile and Key Manager deployer address
   */
  address private UNIVERSAL_PROFILE_DEPLOYER;

  /**
   * @dev Initialize dao an multisig addresses
   */
  constructor(
    address _UNIVERSAL_PROFILE_DEPLOYER,
    address _DAO_DEPLOYER,
    address _MULTISIG_DEPLOYER
  ) {
    UNIVERSAL_PROFILE_DEPLOYER = _UNIVERSAL_PROFILE_DEPLOYER;
    DAO_DEPLOYER = _DAO_DEPLOYER;
    MULTISIG_DEPLOYER = _MULTISIG_DEPLOYER;
  }

  /**
   * @dev Storing the progress of a caller.
   */
  struct Accounts {
    /**
     * @dev The address of the LSP0.
     */
    address payable UNIVERSAL_PROFILE;
    /**
     * @dev The address of the LSP6.
     */
    address KEY_MANAGER;
    /**
     * @dev The address of the LSP6.
     */
    address DAO_PERMISSIONS;
    /**
     * @dev The address of the LSP6.
     */
    address DAO_DELEGATES;
    /**
     * @dev The address of the LSP6.
     */
    address DAO_PROPOSALS;
    /**
     * @dev The address of the LSP6.
     */
    address MULTISIG;
    /**
     * @dev Phase counter
     */
    bytes1 phase;
  }
  mapping(address => Accounts) accountOf;

  /**
   * @dev Check if address is one of the allowed ones
   */
  modifier allowedAddress() {
    require (
      msg.sender == DAO_DEPLOYER ||
      msg.sender == MULTISIG_DEPLOYER ||
      msg.sender == UNIVERSAL_PROFILE_DEPLOYER,
      "Not allowed address."
    );
    _;
  }

  /**
   * @notice Get caller created addresses.
   */
  function getAddresses() external view returns(address[6] memory) {
    return [
      accountOf[msg.sender].UNIVERSAL_PROFILE,
      accountOf[msg.sender].KEY_MANAGER,
      accountOf[msg.sender].DAO_PERMISSIONS,
      accountOf[msg.sender].DAO_DELEGATES,
      accountOf[msg.sender].DAO_PROPOSALS,
      accountOf[msg.sender].MULTISIG
    ];
  }

  /**
   * @notice Deploys UP, Key Manager and update the necessary data for the dao and multisig.
   */
  function deploy(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata,

    bytes memory _JSONDaoMetdata,
    /*bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,*/
    bytes32[] memory _daoData,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions,

    bytes memory _JSONMultisigMetdata,
    bytes32 _multisigQuorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  )
    external
  {
    deployUniversalProfile(
      _unviersalReceiverDelegateUPAddress,
      _universalProfileMetadata
    );
    deployDao(
      _JSONDaoMetdata,
      _daoData[0],
      _daoData[1],
      _daoData[2],
      _daoData[3],
      _daoData[4],
      _daoParticipants,
      _daoParticipantsPermissions
    );
    deployMultisig(
      _JSONMultisigMetdata,
      _multisigQuorum,
      _multisigParticipants,
      _multisigParticipantsPermissions
    );
  }

  /**
   * @notice Deploys UP, Key Manager and update the necessary data for the dao.
   */
  function deploy(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata,

    // Dao parameters
    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  )
    external
  {
    deployUniversalProfile(
      _unviersalReceiverDelegateUPAddress,
      _universalProfileMetadata
    );
    deployDao(
      _JSONDaoMetdata,
      _majority,
      _participationRate,
      _minimumVotingDelay,
      _minimumVotingPeriod,
      _minimumExecutionDelay,
      _daoParticipants,
      _daoParticipantsPermissions
    );
  }

  /**
   * @notice Deploys UP, Key Manager and update the necessary data for the multisig.
   */
  function deploy(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata,

    bytes memory _JSONMultisigMetdata,
    bytes32 _multisigQuorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  )
    external
  {
    deployUniversalProfile(
      _unviersalReceiverDelegateUPAddress,
      _universalProfileMetadata
    );
    deployMultisig(
      _JSONMultisigMetdata,
      _multisigQuorum,
      _multisigParticipants,
      _multisigParticipantsPermissions
    );
  }

  /**
   * @dev Deploy Universal Profile and Key Manager and save the adresses.
   */
  function deployUniversalProfile(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata
  )
    internal
  {
    (address payable _UNIVERSAL_PROFILE, address _KEY_MANAGER) = 
      IUniversalProfileDeployer(UNIVERSAL_PROFILE_DEPLOYER).deployUniversalProfile(
        _unviersalReceiverDelegateUPAddress,
        _universalProfileMetadata
      );
    accountOf[msg.sender].UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    accountOf[msg.sender].KEY_MANAGER = _KEY_MANAGER;
  }

  /**
   * @dev Deploy Dao contracts and save the addresses.
   */
  function deployDao(
    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  )
    internal
  {
    address[] memory _DAO_ADDRESSES =
      IDaoDeployer(DAO_DEPLOYER).deployDao(
        accountOf[msg.sender].UNIVERSAL_PROFILE,
        accountOf[msg.sender].KEY_MANAGER,
        msg.sender,

        _JSONDaoMetdata,
        _majority,
        _participationRate,
        _minimumVotingDelay,
        _minimumVotingPeriod,
        _minimumExecutionDelay,
        _daoParticipants,
        _daoParticipantsPermissions
      );
    accountOf[msg.sender].DAO_PERMISSIONS = _DAO_ADDRESSES[0];
    accountOf[msg.sender].DAO_DELEGATES = _DAO_ADDRESSES[1];
    accountOf[msg.sender].DAO_PROPOSALS = _DAO_ADDRESSES[2];
  }

  /**
   * @dev Deploy the Multisig contract and save the address.
   */
  function deployMultisig(
    bytes memory _JSONMultisigMetdata,
    bytes32 _multisigQuorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  )
    internal
  {
    address _MULTISISG =
      IMultisigDeployer(MULTISIG_DEPLOYER).deployMultisig(
        accountOf[msg.sender].UNIVERSAL_PROFILE,
        accountOf[msg.sender].KEY_MANAGER,
        msg.sender,

        _JSONMultisigMetdata,
        _multisigQuorum,
        _multisigParticipants,
        _multisigParticipantsPermissions
      );
    accountOf[msg.sender].MULTISIG = _MULTISISG;
  }

  /**
   * @dev Get UP data
   */
  function getData(
    address _caller,
    bytes32[] memory dataKeys
  )
    public
    view
    allowedAddress
    returns (bytes[] memory dataValues)
  {
    dataValues = IERC725Y(accountOf[_caller].UNIVERSAL_PROFILE).getData(dataKeys);
  }

  /**
   * @dev Set UP data
   */
  function setData(
    address _caller,
    bytes32[] memory dataKeys,
    bytes[] memory dataValues
  )
    public
    allowedAddress
  {
    IERC725Y(accountOf[_caller].UNIVERSAL_PROFILE).setData(dataKeys, dataValues);
  }

  /**
   * @dev Set data of a Universal Profile
   */
  function setDataOf(
    address _UNIVERSAL_PROFILE,
    bytes32[] memory dataKeys,
    bytes[] memory dataValues
  )
    public
    allowedAddress
  {
    IERC725Y(_UNIVERSAL_PROFILE).setData(dataKeys, dataValues);
  }
}