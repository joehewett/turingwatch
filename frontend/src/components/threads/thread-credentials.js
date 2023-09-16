import { useState, useEffect } from 'react';
import PerfectScrollbar from 'react-perfect-scrollbar';
import {
  Avatar,
  Box,
  Button,
  Card,
  Chip,
  Container,
  Checkbox,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  Typography
} from '@mui/material';
import { Loading } from '../loading';
import { CredentialChip } from '../credential-chip';

export const ThreadCredentials = ({ loading, credentials, ...rest }) => {

  const [selectedCredentialIds, setSelectedCredentialIds] = useState([]);
  const [limit, setLimit] = useState(10);
  const [page, setPage] = useState(0);

  console.log("Credentials:")
  console.log(credentials)
  const handleSelectAll = (event) => {
    let newSelectedCredentialIds;

    if (event.target.checked) {
      newSelectedCredentialIds = credentials.map((credential) => credential.id);
    } else {
      newSelectedCredentialIds = [];
    }

    setSelectedCredentialIds(newSelectedCredentialIds);
  };

  const handleSelectOne = (event, id) => {
    const selectedIndex = selectedCredentialIds.indexOf(id);
    let newSelectedCredentialIds = [];

    if (selectedIndex === -1) {
      newSelectedCredentialIds = newSelectedCredentialIds.concat(selectedCredentialIds, id);
    } else if (selectedIndex === 0) {
      newSelectedCredentialIds = newSelectedCredentialIds.concat(selectedCredentialIds.slice(1));
    } else if (selectedIndex === selectedCredentialIds.length - 1) {
      newSelectedCredentialIds = newSelectedCredentialIds.concat(selectedCredentialIds.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelectedCredentialIds = newSelectedCredentialIds.concat(
        selectedCredentialIds.slice(0, selectedIndex),
        selectedCredentialIds.slice(selectedIndex + 1)
      );
    }

    setSelectedCredentialIds(newSelectedCredentialIds);
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

  if (credentials.length == 0) {
    return (
      <Typography>No credentials have been identified in this email chain.</Typography>
    );
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
                    checked={selectedCredentialIds.length === credentials.length}
                    color="primary"
                    indeterminate={
                      selectedCredentialIds.length > 0
                      && selectedCredentialIds.length < credentials.length
                    }
                    onChange={handleSelectAll}
                  />
                </TableCell>
                <TableCell>
                  Category
                </TableCell>
                <TableCell>
                  Message ID
                </TableCell>
                <TableCell>
                  Value
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {
                credentials.slice(limit*page, limit*page+limit).map((credential) => (
                  <TableRow
                    hover
                    key={credential.id}
                    selected={selectedCredentialIds.indexOf(credential.id) !== -1}
                  >
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selectedCredentialIds.indexOf(credential.id) !== -1}
                        onChange={(event) => handleSelectOne(event, credential.id)}
                        value="true"
                      />
                    </TableCell>
                    <TableCell>
                      <CredentialChip category={credential.category} />
                    </TableCell>
                    <TableCell>
                      {credential.message_id}
                    </TableCell>
                    <TableCell>
                      {credential.value}
                    </TableCell>
                  </TableRow>
                ))
              }
            </TableBody>
          </Table>
        </Box>
      </PerfectScrollbar>
      {/* <TablePagination
        component="div"
        count={credentials.length}
        onPageChange={handlePageChange}
        onRowsPerPageChange={handleLimitChange}
        page={page}
        rowsPerPage={limit}
        rowsPerPageOptions={[5, 10, 25]}
      /> */}
    </Card>
  );
};
