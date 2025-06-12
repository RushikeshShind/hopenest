const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// MySQL Connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Rushi@9324',
  database: 'hopenest',
});

db.connect((err) => {
  if (err) {
    console.error('Failed to connect to MySQL:', err);
    process.exit(1);
  }
  console.log('MySQL Connected');
});

// Sign-Up Endpoint
app.post('/api/signup', (req, res) => {
  const { email, password, role, dob, gender, orphanageName } = req.body;

  if (!email || !password || !role) {
    return res.status(400).json({ success: false, message: 'Email, password, and role are required' });
  }
  if (role === 'donor' && (!dob || !gender)) {
    return res.status(400).json({ success: false, message: 'Date of birth and gender are required for donors' });
  }
  if (role === 'orphanage_admin' && !orphanageName) {
    return res.status(400).json({ success: false, message: 'Orphanage name is required for orphanage admins' });
  }
  if (role !== 'donor' && role !== 'orphanage_admin') {
    return res.status(400).json({ success: false, message: 'Invalid role. Must be "donor" or "orphanage_admin"' });
  }

  const checkQuery = 'SELECT * FROM users WHERE email = ?';
  db.query(checkQuery, [email], (err, result) => {
    if (err) {
      console.error('Error checking email:', err);
      return res.status(500).json({ success: false, message: 'Server error while checking email' });
    }
    if (result.length > 0) {
      return res.status(409).json({ success: false, message: 'Email already exists' });
    }

    const insertUserQuery = 'INSERT INTO users (email, password, role, dob, gender) VALUES (?, ?, ?, ?, ?)';
    db.query(insertUserQuery, [email, password, role, dob || null, gender || null], (err, userResult) => {
      if (err) {
        console.error('Error inserting user:', err);
        return res.status(500).json({ success: false, message: 'Failed to create user', error: err.message });
      }

      const userId = userResult.insertId;

      if (role === 'orphanage_admin') {
        // Create an orphanage for the new admin
        const insertOrphanageQuery = 'INSERT INTO orphanages (name, location, description, contact, needs, image_url, rating, user_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
        db.query(
          insertOrphanageQuery,
          [orphanageName, '', '', email, JSON.stringify([]), null, 0, userId],
          (err, orphanageResult) => {
            if (err) {
              console.error('Error creating orphanage:', err);
              // Rollback user creation if orphanage creation fails
              db.query('DELETE FROM users WHERE id = ?', [userId], (rollbackErr) => {
                if (rollbackErr) {
                  console.error('Error rolling back user creation:', rollbackErr);
                }
                return res.status(500).json({ success: false, message: 'Failed to create orphanage', error: err.message });
              });
              return;
            }
            res.status(201).json({ success: true, userId });
          }
        );
      } else {
        res.status(201).json({ success: true, userId });
      }
    });
  });
});

// Login Endpoint
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required' });
  }

  const query = 'SELECT * FROM users WHERE email = ? AND password = ?';
  db.query(query, [email, password], (err, result) => {
    if (err) {
      console.error('Error during login:', err);
      return res.status(500).json({ success: false, message: 'Server error during login' });
    }
    if (result.length > 0) {
      res.json({ success: true, user: result[0] });
    } else {
      res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
  });
});

// Get Orphanages by Location
app.get('/api/orphanages', (req, res) => {
  const { location } = req.query;
  if (!location) {
    return res.status(400).json({ success: false, message: 'Location query parameter is required' });
  }

  const query = 'SELECT * FROM orphanages WHERE LOWER(location) LIKE LOWER(?)';
  db.query(query, [`%${location}%`], (err, result) => {
    if (err) {
      console.error('Error fetching orphanages:', err);
      return res.status(500).json({ success: false, message: 'Server error fetching orphanages' });
    }
    res.json(result);
  });
});

// Create a New Orphanage
app.post('/api/orphanages', (req, res) => {
  const { name, location, description, contact, needs, image_url, user_id } = req.body;
  if (!name || !location || !contact) {
    return res.status(400).json({ success: false, message: 'Name, location, and contact are required' });
  }

  const query = 'INSERT INTO orphanages (name, location, description, contact, needs, image_url, rating, user_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
  const needsJson = needs ? JSON.stringify(needs) : JSON.stringify([]);
  db.query(query, [name, location, description || null, contact, needsJson, image_url || null, 0, user_id || null], (err, result) => {
    if (err) {
      console.error('Error saving orphanage:', err);
      return res.status(500).json({ success: false, message: 'Failed to save orphanage', error: err.message });
    }
    res.status(201).json({ success: true, orphanageId: result.insertId });
  });
});

// Get Orphanage by Admin ID
app.get('/api/orphanage/admin/:adminId', (req, res) => {
  const { adminId } = req.params;
  const query = 'SELECT * FROM orphanages WHERE user_id = ?';
  db.query(query, [adminId], (err, result) => {
    if (err) {
      console.error('Error fetching orphanage for admin:', err);
      return res.status(500).json({ success: false, message: 'Server error fetching orphanage' });
    }
    if (result.length === 0) {
      return res.status(404).json({ success: false, message: 'Orphanage not found for this admin' });
    }
    res.json(result[0]);
  });
});

// Add Donation
app.post('/api/donations', (req, res) => {
  const { orphanageId, donorId, items, total, status } = req.body;
  if (!orphanageId || !donorId || !items || !total || !status) {
    return res.status(400).json({ success: false, message: 'Missing required fields (orphanageId, donorId, items, total, status)' });
  }

  const query = 'INSERT INTO donations (orphanage_id, donor_id, items, total, status) VALUES (?, ?, ?, ?, ?)';
  db.query(query, [orphanageId, donorId, JSON.stringify(items), total, status], (err, result) => {
    if (err) {
      console.error('Error saving donation:', err);
      return res.status(500).json({ success: false, message: 'Failed to save donation', error: err.message });
    }
    res.status(201).json({ success: true, donationId: result.insertId });
  });
});

// Get All Donations (with optional orphanage_id filter)
app.get('/api/donations', (req, res) => {
  const { orphanage_id } = req.query;
  let query = 'SELECT d.*, u.email AS donor_email FROM donations d JOIN users u ON d.donor_id = u.id';
  let params = [];

  if (orphanage_id) {
    query += ' WHERE d.orphanage_id = ?';
    params.push(orphanage_id);
  }

  db.query(query, params, (err, result) => {
    if (err) {
      console.error('Error fetching donations:', err);
      return res.status(500).json({ success: false, message: 'Server error fetching donations' });
    }
    res.json(result);
  });
});

// Get Donations by Donor ID
app.get('/api/donations/donor/:donorId', (req, res) => {
  const { donorId } = req.params;
  const query = 'SELECT * FROM donations WHERE donor_id = ?';
  db.query(query, [donorId], (err, result) => {
    if (err) {
      console.error('Error fetching donations for donor:', err);
      return res.status(500).json({ success: false, message: 'Server error fetching donations' });
    }
    res.json(result);
  });
});

// Update Donation Status
app.put('/api/donations/:id', (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status) {
    return res.status(400).json({ success: false, message: 'Status is required' });
  }

  const query = 'UPDATE donations SET status = ? WHERE id = ?';
  db.query(query, [status, id], (err, result) => {
    if (err) {
      console.error('Error updating donation status:', err);
      return res.status(500).json({ success: false, message: 'Server error updating donation status' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }
    res.json({ success: true });
  });
});

// Update Orphanage Details
app.put('/api/orphanages/:id', (req, res) => {
  const { id } = req.params;
  const { name, location, description, contact, needs, image_url } = req.body;
  if (!name || !location || !contact) {
    return res.status(400).json({ success: false, message: 'Name, location, and contact are required' });
  }

  const query = 'UPDATE orphanages SET name = ?, location = ?, description = ?, contact = ?, needs = ?, image_url = ? WHERE id = ?';
  const needsJson = needs ? JSON.stringify(needs) : JSON.stringify([]);
  db.query(query, [name, location, description || null, contact, needsJson, image_url || null, id], (err, result) => {
    if (err) {
      console.error('Error updating orphanage:', err);
      return res.status(500).json({ success: false, message: 'Server error updating orphanage' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Orphanage not found' });
    }
    res.json({ success: true });
  });
});

// Delete User (Super Admin only)
app.delete('/api/users/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM users WHERE id = ? AND role != "super_admin"';
  db.query(query, [id], (err, result) => {
    if (err) {
      console.error('Error deleting user:', err);
      return res.status(500).json({ success: false, message: 'Server error deleting user' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User not found or cannot delete super admin' });
    }
    res.json({ success: true });
  });
});
app.get('/api/user/:userId', (req, res) => {
  const { userId } = req.params;
  const query = 'SELECT email, role FROM users WHERE id = ?';
  db.query(query, [userId], (err, result) => {
    if (err) {
      console.error('Error fetching user profile:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    if (result.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json(result[0]);
  });
});


// Get All Users (for Super Admin)
app.get('/api/users', (req, res) => {
  const query = 'SELECT * FROM users';
  db.query(query, (err, result) => {
    if (err) {
      console.error('Error fetching users:', err);
      return res.status(500).json({ success: false, message: 'Server error fetching users' });
    }
    res.json(result);
  });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});