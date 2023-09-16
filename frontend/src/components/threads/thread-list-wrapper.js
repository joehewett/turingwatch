import { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Button,
  Typography
} from '@mui/material';
import { getThreadsInfo } from '../../services/threads'
import { ThreadListResults } from './thread-list-results';
import { ThreadListToolbar } from './thread-list-toolbar';
import { makeStyles } from '@material-ui/core/styles'
import { Loading } from '../loading';

const useStyles = makeStyles(theme => ({
  marginAutoContainer: {
    width: 500,
    height: 80,
    display: 'flex',
    backgroundColor: 'gold',
  },
  marginAutoItem: {
    margin: 'auto'
  },
  alignItemsAndJustifyContent: {
    width: 500,
    height: 80,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'pink',
  },
}))

export const ThreadListWrapper = ({ ...rest }) => {
  const [threads, setThreads] = useState([]);
  const [filteredThreads, setFilteredThreads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    if (loading) return; 
    let filtered = threads.filter((thread) => {
      console.log("Thread:")
      console.log(thread)
      if (thread.first_name.includes(search) ||
          thread.last_name.includes(search)  ||
          thread.scammer_address.includes(search)  ||
          thread.created.includes(search)  ||
          thread.last_updated.includes(search)) {
            return true; 
      }
      return false; 
    });
    setFilteredThreads(filtered);

  }, [search]);

  // Load thread info
  useEffect(() => {
    let mounted = true;
    getThreadsInfo().then(items => {
      if (mounted) {
        const sortedThreads = items.threads.sort((a,b) => Date.parse(b.last_updated) - Date.parse(a.last_updated));
        console.log(sortedThreads)
        setThreads(sortedThreads);
        setFilteredThreads(sortedThreads);
      }
      setLoading(false);
    });
    return () => mounted = false;
  }, []);

  const print = () => {
    console.log(threads);
  }

  if (loading) {
    return <Loading />;
  }

  return (
    <Box
      component="main"
      sx={{
        flexGrow: 1,
        py: 8
      }}
    >
      <Container maxWidth={false}>
        <ThreadListToolbar search={search} setSearch={setSearch} />
        <Box sx={{ mt: 3 }}>
          <Button onClick={print}>Print</Button>
          <ThreadListResults loading={loading} threads={filteredThreads} />
        </Box>
      </Container>
    </Box>
  );
};
