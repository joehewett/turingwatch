import { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Button,
  Typography,
} from '@mui/material';
import { ThreadMessages } from './thread-messages';
import { ThreadCredentials } from './thread-credentials';
import { getThreadMessages, getThreadInfo, getThreadCredentials } from '../../services/threads'
import { Loading } from '../loading';

const defaultInfo = {
  persona_name: "",
  persona_email: "",
  fraudster_email: ""
}

export const ThreadDetails = ({ id, persona_name, fraudster_email, ...rest }) => {
  const [messages, setMessages] = useState([]);
  const [expandAll, setExpandAll] = useState(false);
  const [info, setInfo] = useState(defaultInfo);
  const [credentials, setCredentials] = useState([]);

  const [loadingMessages, setLoadingMessages] = useState(true);
  const [loadingInfo, setLoadingInfo] = useState(true);
  const [loadingCredentials, setLoadingCredentials] = useState(true);

  const showAllMessages = () => {
    let current = expandAll; 
    setExpandAll(!current);
  }

  // Load the messages for this thread_id to pass to <ThreadMessages>
  useEffect(() => {
    let mounted = true;
    getThreadMessages(id).then(items => {
      if (mounted) {
        const sentMessages = items.sent_messages.map(s => ({...s, type: 'sent'}));
        const receivedMessages = items.received_messages.map(r => ({...r, type: 'received'}));
        const allMessages = sentMessages.concat(receivedMessages);
        const sortedMessages = allMessages.sort((a,b) => Date.parse(b.datetime) - Date.parse(a.datetime));

        setMessages(sortedMessages);
      }
      setLoadingMessages(false);
    });
    return () => mounted = false;
  }, []);

  // Load the info for this email thread (to, from) 
  useEffect(() => {
    let mounted = true;
    getThreadInfo(id).then(items => {
      if (mounted) {
        setInfo(items.thread[0]);
        console.log(items.thread[0]);
      }
      setLoadingInfo(false);
    });
    return () => mounted = false;
  }, []);

  // Load any credentials that have been loaded from this email thread
  useEffect(() => {
    let mounted = true;
    getThreadCredentials(id).then(items => {
      if (mounted) {
        setCredentials(items.credentials);
        console.log(items);
      }
      setLoadingCredentials(false);
    });
    return () => mounted = false;
  }, []);

  const print = () => {
    console.log(messages);
  }

  if (loadingMessages || loadingInfo) {
    return <Loading />;
  }

  return (
    <Box
      component="main"
      sx={{
        flexGrow: 1,
        py: 8,
        m: 3
      }}
    >
      <Container maxWidth={false}>
        <Typography
          sx={{ m: 1 }}
          variant="h4"
        >
          {`Thread #${id}`} 
        </Typography>
        <Typography
          sx={{ m: 1 }}
        >
          {`A thread of ${messages.length} emails between persona `}<b>{`${info.first_name} ${info.last_name} (${info.email_address})`}</b>{` and a fraudster `}<b>{`${info.scammer_address}`}</b>{`.`}
        </Typography>
        <Typography
          sx={{ m: 1 }}
        >
          {`Last update `}<b>{`${info.last_updated}`}</b>
        </Typography>

        <Box sx={{ mt: 3, mx: 1}}>
          <ThreadCredentials loading={loadingCredentials} credentials={credentials} />
        </Box>

        <Box sx={{ mt: 3 }}>
          <Button onClick={print}>Print to Console</Button>
          <Button onClick={showAllMessages}>Expand All</Button>
          <ThreadMessages expandAll={expandAll} messages={messages} />
        </Box>
      </Container>
    </Box>
  );
};
