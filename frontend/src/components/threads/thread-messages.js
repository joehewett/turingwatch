import { useState, useEffect } from 'react';
import {
  Typography,
  Accordion,
  AccordionDetails,
  AccordionSummary,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { v4 as uuidv4 } from 'uuid';

export const ThreadMessages = ({ expandAll, messages, ...rest }) => {
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(false);

  // Toggle an individual panel
  const handleChange = (panel) => (event, isExpanded) => {
    setExpanded(isExpanded ? panel : false);
  };

  if (messages.length == 0) {
    return <h6>There don't appear to be any messages in this email chain.</h6>
  }
  return (
    <div>
      {messages.map((message, index) => (
        <Accordion 
          expanded={expanded === `panel${index}` || expandAll} 
          onChange={handleChange(`panel${index}`)}
          key={message.id}
          sx={message.type == 'sent' ? {backgroundColor: "#fffff9"} : {backgroundColor: "#adbdf0"}}
        >
          <AccordionSummary
            expandIcon={<ExpandMoreIcon />}
            aria-controls="panel1bh-content"
            id={`panel${index}bh-header`}
          >
            <Typography sx={{ width: '33%', flexShrink: 0, fontWeight: 600 }}>
              {message.subject}
            </Typography>
            <Typography sx={{ width: '33%', color: 'text.secondary' }}>
              {message.datetime}
            </Typography>
          </AccordionSummary>
          <AccordionDetails>
            {message.body.split('\n').map((line,i) => <Typography key={i}>{line }</Typography>)}
          </AccordionDetails>
        </Accordion>
        )
      )}
    </div>
  );
};
