{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeApplications #-}

-- base
import Control.Exception (throwIO)
import Control.Monad.IO.Class (liftIO)
-- butcher

-- bytestring

-- monad-loops
import Control.Monad.Loops (iterateUntil)
-- mtl
import Control.Monad.Reader (runReaderT)
import Data.ByteString.Lazy.Char8 qualified as BL
import Data.Functor (void)
-- pretty-simple

-- slack-web

-- text
import Data.Text qualified as Text
import Data.Text.Lazy qualified as TextLazy
-- time
import Data.Time.Clock (addUTCTime, getCurrentTime, nominalDay)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
-- servant-client-core
import Servant.Client.Core (ClientError (..), Response, ResponseF (..))
import System.Environment (getEnv)
import System.Exit (die)
import System.IO (hPutStrLn, stderr)
import Text.Pretty.Simple (pPrint, pShow)
import Text.Read (readMaybe)
import UI.Butcher.Monadic
import Web.Slack.Classy qualified as Slack
import Web.Slack.Common qualified as Slack
import Web.Slack.Conversation qualified as SlackConversation

main :: IO ()
main = do
  apiConfig <- Slack.mkSlackConfig . Text.pack =<< getEnv "SLACK_API_TOKEN"
  mainFromCmdParserWithHelpDesc $ \helpDesc -> do
    addHelpCommand helpDesc
    addCmd "conversations.list" . addCmdImpl $ do
      let listReq =
            SlackConversation.ListReq
              { SlackConversation.listReqExcludeArchived = Just True
              , SlackConversation.listReqTypes =
                  [ SlackConversation.PublicChannelType
                  , SlackConversation.PrivateChannelType
                  , SlackConversation.MpimType
                  , SlackConversation.ImType
                  ]
              }
      Slack.conversationsList listReq
        `runReaderT` apiConfig
        >>= \case
          Right (SlackConversation.ListRsp cs) -> do
            pPrint cs
          Left err -> do
            peepInResponseBody err
            hPutStrLn stderr "Error when fetching the list of conversations:"
            die . TextLazy.unpack $ pShow err

    addCmd "conversations.history" $ do
      conversationId <-
        Slack.ConversationId
          . Text.pack
          <$> addParamString "CONVERSATION_ID" (paramHelpStr "ID of the conversation to fetch")
      getsAll <- addSimpleBoolFlag "A" ["all"] (flagHelpStr "Get all available messages in the channel")
      addCmdImpl
        $ if getsAll
          then do
            (`runReaderT` apiConfig) $ do
              fetchPage <- Slack.conversationsHistoryAll $ (SlackConversation.mkHistoryReq conversationId) {SlackConversation.historyReqCount = 2}
              void . iterateUntil null $ do
                result <- either (liftIO . throwIO) return =<< fetchPage
                liftIO $ pPrint result
                return result
          else do
            nowUtc <- getCurrentTime
            let now = Slack.mkSlackTimestamp nowUtc
                thirtyDaysAgo = Slack.mkSlackTimestamp $ addUTCTime (nominalDay * negate 30) nowUtc
                histReq =
                  SlackConversation.HistoryReq
                    { SlackConversation.historyReqChannel = conversationId
                    , SlackConversation.historyReqCount = 5
                    , SlackConversation.historyReqLatest = Just now
                    , SlackConversation.historyReqOldest = Just thirtyDaysAgo
                    , SlackConversation.historyReqInclusive = True
                    , SlackConversation.historyReqCursor = Nothing
                    }
            Slack.conversationsHistory histReq
              `runReaderT` apiConfig
              >>= \case
                Right rsp ->
                  pPrint rsp
                Left err -> do
                  peepInResponseBody err
                  hPutStrLn stderr "Error when fetching the history of conversations:"
                  die . TextLazy.unpack $ pShow err

    addCmd "conversations.replies" $ do
      conversationId <-
        Slack.ConversationId
          . Text.pack
          <$> addParamString "CONVERSATION_ID" (paramHelpStr "ID of the conversation to fetch")
      threadTimeStampStr <- addParamString "TIMESTAMP" (paramHelpStr "Timestamp of the thread to fetch")
      let ethreadTimeStamp = Slack.timestampFromText $ Text.pack threadTimeStampStr
      pageSize <- addParamRead "PAGE_SIZE" (paramHelpStr "How many messages to get by a request.")
      addCmdImpl $ do
        -- NOTE: butcher's CmdParser isn't a MonadFail
        threadTimeStamp <-
          either
            (\emsg -> fail $ "Invalid timestamp " ++ show threadTimeStampStr ++ ": " ++ emsg)
            return
            ethreadTimeStamp
        nowUtc <- getCurrentTime
        let now = Slack.mkSlackTimestamp nowUtc
            tenDaysAgo = Slack.mkSlackTimestamp $ addUTCTime (nominalDay * negate 10) nowUtc
            req =
              (SlackConversation.mkRepliesReq conversationId threadTimeStamp)
                { SlackConversation.repliesReqLimit = pageSize
                , SlackConversation.repliesReqLatest = Just now
                , SlackConversation.repliesReqOldest = Just tenDaysAgo
                }
        (`runReaderT` apiConfig) $ do
          fetchPage <- Slack.repliesFetchAll req
          void . iterateUntil null $ do
            result <- either (liftIO . throwIO) return =<< fetchPage
            liftIO $ pPrint result
            return result

peepInResponseBody err = do
  {- Uncomment these lines when you want to see the JSON in the reponse body.
  case err of
    Slack.ServantError (DecodeFailure _ res) ->
      BL.putStrLn $ responseBody res
    _ -> return ()
  -}
  return ()
