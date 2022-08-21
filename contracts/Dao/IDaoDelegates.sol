// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.10;

/**
 * @author B00ste
 * @title IDaoDelegates
 * @custom:version 1.5
 */
interface IDaoDelegates {
    /**
     * @notice Delegate a vote.
     *
     * @param delegatee The address of the delegatee to be set for `msg.sender`.
     *
     * Requirements:
     * - `msg.sender` must have SEND_DELEGATE permission.
     * - `delegatee` must have RECEIVE_DELEGATE permission.
     * - `msg.sender` must have no delegatee set.
     */
    function delegate(address delegatee) external;

    /**
     * @notice Change a delegatee.
     *
     * @param newDelegatee The address of the new delegatee to be set for `msg.sender`.
     *
     * Requirements:
     * - `msg.sender` must have SEND_DELEGATE permission.
     * - `newDelegatee` must have RECEIVE_DELEGATE permission.
     * - `msg.sender` must have a delegatee set.
     * - `newDelegatee` must be different from the current delegatee of `msg.sender`.
     */
    function changeDelegate(address newDelegatee) external;

    /**
     * @notice Remove a delegatee.
     *
     * Requirements:
     * - `msg.sender` must have SEND_DELEGATE permission.
     * - `msg.sender` must have a delegatee set.
     */
    function undelegate() external;
}
