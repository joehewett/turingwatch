import PropTypes from 'prop-types';
import { styled } from '@mui/material/styles';
import logo from './turingwatch-logo.png'
import {
  Box,
  Container,
  Button,
  Typography,
} from '@mui/material';

export const Logo = styled((props) => {
  const { variant, ...other } = props;

  const color = variant === 'light' ? '#C1C4D6' : '#5048E5';
  return (
    // <svg
    //   width="42"
    //   height="42"
    //   viewBox="0 0 42 42"
    //   xmlns="http://www.w3.org/2000/svg"
    //   {...other}>
    // </svg>
    <Box sx={{ maxWidth: 100, height: 100}}>
      <img src="https://i.imgur.com/ssAa83x.png"></img>
    </Box>
  );
})``;

Logo.defaultProps = {
  variant: 'primary'
};

Logo.propTypes = {
  variant: PropTypes.oneOf(['light', 'primary'])
};
