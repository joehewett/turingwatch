import PropTypes from 'prop-types';
import { Box, Chip } from '@mui/material';
import HashLoader from 'react-spinners/HashLoader';
import AccountBalanceRoundedIcon from '@mui/icons-material/AccountBalanceRounded';
import ContactMailRoundedIcon from '@mui/icons-material/ContactMailRounded';

export const CredentialChip = ({ category }) => {

  if (category == 'bank_account') {
    return (
      <Chip 
        label="Bank Details"
        variant="filled" 
        icon={<AccountBalanceRoundedIcon />}
        color="success"
      />
    );
  }
  if (category == 'email') {
    return (
      <Chip 
        label="Secondary Email"
        variant="filled" 
        icon={<ContactMailRoundedIcon />}
        color="info"
      />
    );
  }
};

