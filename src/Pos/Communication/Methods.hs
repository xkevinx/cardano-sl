-- | Wrappers on top of communication methods

module Pos.Communication.Methods
       ( sendTx
       , sendVote
       , sendUpdateProposal
       ) where

import           Formatting                 (sformat, (%))
import           System.Wlog                (logInfo)
import           Universum

import           Pos.Binary.Communication   ()
import           Pos.Binary.Core            ()
import           Pos.Binary.Relay           ()
import           Pos.Communication.Message  ()
import           Pos.Communication.Protocol (NodeId, SendActions)
import           Pos.Communication.Relay    (invReqDataFlowTK)
import           Pos.Crypto                 (hash, hashHexF)
import           Pos.DB.Limits              (MonadDBLimits)
import           Pos.Txp.Core.Types         (TxAux)
import           Pos.Txp.Network.Types      (TxMsgContents (..))
import           Pos.Update                 (UpId, UpdateProposal, UpdateVote, mkVoteId)
import           Pos.WorkMode.Class         (MinWorkMode)


-- | Send Tx to given address.
sendTx
    :: (MinWorkMode m, MonadDBLimits m)
    => SendActions m -> NodeId -> TxAux -> m ()
sendTx sendActions addr (tx,w,d) =
    invReqDataFlowTK "tx" sendActions addr (hash tx) (TxMsgContents tx w d)

-- Send UpdateVote to given address.
sendVote
    :: (MinWorkMode m, MonadDBLimits m)
    => SendActions m -> NodeId -> UpdateVote -> m ()
sendVote sendActions addr vote =
    invReqDataFlowTK "UpdateVote" sendActions addr (mkVoteId vote) vote

-- Send UpdateProposal to given address.
sendUpdateProposal
    :: (MinWorkMode m, MonadDBLimits m)
    => SendActions m
    -> NodeId
    -> UpId
    -> UpdateProposal
    -> [UpdateVote]
    -> m ()
sendUpdateProposal sendActions addr upid proposal votes = do
    logInfo $ sformat ("Announcing proposal with id "%hashHexF) upid
    invReqDataFlowTK
        "UpdateProposal"
        sendActions
        addr
        upid
        (proposal, votes)
