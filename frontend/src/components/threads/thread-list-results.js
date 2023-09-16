import { useState, useEffect } from 'react';
import PerfectScrollbar from 'react-perfect-scrollbar';
import PropTypes from 'prop-types';
import { format } from 'date-fns';
import NextLink from 'next/link';
import {
  Avatar,
  Box,
  Button,
  Card,
  Checkbox,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  Typography
} from '@mui/material';
import { getInitials } from '../../utils/get-initials';
import { Loading } from '../loading';

export const ThreadListResults = ({ loading, threads, ...rest }) => {
  const [selectedThreadIds, setSelectedThreadIds] = useState([]);
  const [limit, setLimit] = useState(10);
  const [page, setPage] = useState(0);

  const handleSelectAll = (event) => {
    let newSelectedThreadIds;

    if (event.target.checked) {
      newSelectedThreadIds = threads.map((thread) => thread.id);
    } else {
      newSelectedThreadIds = [];
    }

    setSelectedThreadIds(newSelectedThreadIds);
  };

  const handleSelectOne = (event, id) => {
    const selectedIndex = selectedThreadIds.indexOf(id);
    let newSelectedThreadIds = [];

    if (selectedIndex === -1) {
      newSelectedThreadIds = newSelectedThreadIds.concat(selectedThreadIds, id);
    } else if (selectedIndex === 0) {
      newSelectedThreadIds = newSelectedThreadIds.concat(selectedThreadIds.slice(1));
    } else if (selectedIndex === selectedThreadIds.length - 1) {
      newSelectedThreadIds = newSelectedThreadIds.concat(selectedThreadIds.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelectedThreadIds = newSelectedThreadIds.concat(
        selectedThreadIds.slice(0, selectedIndex),
        selectedThreadIds.slice(selectedIndex + 1)
      );
    }

    setSelectedThreadIds(newSelectedThreadIds);
  };

  const handleLimitChange = (event) => {
    setLimit(event.target.value);
  };

  const handlePageChange = (event, newPage) => {
    setPage(newPage);
  };

  if (loading) {
    return <Loading />; 
  }
  return (
    <Card {...rest}>
      <PerfectScrollbar>
        <Box sx={{ minWidth: 1050 }}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell padding="checkbox">
                  <Checkbox
                    checked={selectedThreadIds.length === threads.length}
                    color="primary"
                    indeterminate={
                      selectedThreadIds.length > 0
                      && selectedThreadIds.length < threads.length
                    }
                    onChange={handleSelectAll}
                  />
                </TableCell>
                <TableCell>
                  Persona ID
                </TableCell>
                <TableCell>
                  Fraudster Email
                </TableCell>
                <TableCell>
                  Initiated
                </TableCell>
                <TableCell>
                  Last Updated 
                </TableCell>
                <TableCell>
                  View Thread
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {
                threads.slice(limit*page, limit*page+limit).map((thread) => (
                  <TableRow
                    hover
                    key={thread.id}
                    selected={selectedThreadIds.indexOf(thread.id) !== -1}
                  >
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selectedThreadIds.indexOf(thread.id) !== -1}
                        onChange={(event) => handleSelectOne(event, thread.id)}
                        value="true"
                      />
                    </TableCell>
                    <TableCell>
                      <NextLink
                        href={`/persona/${thread.persona_id}`}
                        passHref
                      >
                        <a>
                          <Button size="small">
                            {`${thread.first_name} ${thread.last_name}`}
                          </Button>
                        </a>
                      </NextLink>
                    </TableCell>
                    <TableCell>
                      {thread.scammer_address}
                    </TableCell>
                    <TableCell>
                      {thread.created}
                    </TableCell>
                    <TableCell>
                      {/* {format(thread.last_updated, 'dd/MM/yyyy')} */}
                      {thread.last_updated}
                    </TableCell>
                    <TableCell>
                      <NextLink
                        href={{
                          pathname: "/thread",
                          query: {id: thread.id}
                        }}
                        passHref
                      >
                        <a>
                          <Button variant="outlined" size="small">
                            View
                          </Button>
                        </a>
                      </NextLink>
                    </TableCell>
                  </TableRow>
                ))
              }
            </TableBody>
          </Table>
        </Box>
      </PerfectScrollbar>
      <TablePagination
        component="div"
        count={threads.length}
        onPageChange={handlePageChange}
        onRowsPerPageChange={handleLimitChange}
        page={page}
        rowsPerPage={limit}
        rowsPerPageOptions={[5, 10, 25]}
      />
    </Card>
  );
};
