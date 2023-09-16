import PropTypes from 'prop-types';
import { Box } from '@mui/material';
import HashLoader from 'react-spinners/HashLoader';

export const Loading = () => {

  return (
    <Box
      display="flex"
      width={"100%"}
      height={"100%"}
    >
      <Box m="auto">
        <div className="sweet-loading">
          <HashLoader size={40} color={"#123abc"} loading={true} speedMultiplier={1.5} />
        </div>
      </Box>
    </Box>
  );
};
