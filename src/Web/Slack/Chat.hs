{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

----------------------------------------------------------------------

----------------------------------------------------------------------

-- |
-- Module: Web.Slack.Chat
-- Description:
module Web.Slack.Chat
  ( PostMsg (..),
    PostMsgReq (..),
    mkPostMsgReq,
    PostMsgRsp (..),
  )
where

-- FIXME: Web.Slack.Prelude

-- aeson

-- base

-- deepseq
import Control.DeepSeq (NFData)
import Data.Aeson.TH
-- http-api-data

-- slack-web

-- text
import Data.Text (Text)
import GHC.Generics (Generic)
import Web.FormUrlEncoded
import Web.Slack.Util
import Prelude

data PostMsg = PostMsg
  { postMsgText :: Text
  , postMsgParse :: Maybe Text
  , postMsgLinkNames :: Maybe Bool
  , postMsgAttachments :: Maybe Text
  , postMsgUnfurlLinks :: Maybe Bool
  , postMsgUnfurlMedia :: Maybe Bool
  , postMsgUsername :: Maybe Text
  , postMsgAsUser :: Maybe Bool
  , postMsgIconUrl :: Maybe Text
  , postMsgIconEmoji :: Maybe Text
  , postMsgThreadTs :: Maybe Text
  , postMsgReplyBroadcast :: Maybe Bool
  }
  deriving stock (Eq, Generic, Show)

instance NFData PostMsg

$(deriveJSON (jsonOpts "postMsg") ''PostMsg)

data PostMsgReq = PostMsgReq
  { postMsgReqChannel :: Text
  , postMsgReqText :: Text
  , postMsgReqParse :: Maybe Text
  , postMsgReqLinkNames :: Maybe Bool
  , postMsgReqAttachments :: Maybe Text
  , postMsgReqBlocks :: Maybe Text
  , postMsgReqUnfurlLinks :: Maybe Bool
  , postMsgReqUnfurlMedia :: Maybe Bool
  , postMsgReqUsername :: Maybe Text
  , postMsgReqAsUser :: Maybe Bool
  , postMsgReqIconUrl :: Maybe Text
  , postMsgReqIconEmoji :: Maybe Text
  , postMsgReqThreadTs :: Maybe Text
  , postMsgReqReplyBroadcast :: Maybe Bool
  }
  deriving stock (Eq, Generic, Show)

instance NFData PostMsgReq

$(deriveJSON (jsonOpts "postMsgReq") ''PostMsgReq)

instance ToForm PostMsgReq where
  toForm =
    genericToForm (formOpts "postMsgReq")

mkPostMsgReq ::
  Text ->
  Text ->
  PostMsgReq
mkPostMsgReq channel text =
  PostMsgReq
    { postMsgReqChannel = channel
    , postMsgReqText = text
    , postMsgReqParse = Nothing
    , postMsgReqLinkNames = Nothing
    , postMsgReqAttachments = Nothing
    , postMsgReqBlocks = Nothing
    , postMsgReqUnfurlLinks = Nothing
    , postMsgReqUnfurlMedia = Nothing
    , postMsgReqUsername = Nothing
    , postMsgReqAsUser = Nothing
    , postMsgReqIconUrl = Nothing
    , postMsgReqIconEmoji = Nothing
    , postMsgReqThreadTs = Nothing
    , postMsgReqReplyBroadcast = Nothing
    }

data PostMsgRsp = PostMsgRsp
  { postMsgRspTs :: String
  , postMsgRspMessage :: PostMsg
  }
  deriving stock (Eq, Generic, Show)

instance NFData PostMsgRsp

$(deriveFromJSON (jsonOpts "postMsgRsp") ''PostMsgRsp)
