require('dotenv').config();
const express = require('express');
const { connect } = require('mongoose');
const jwt = require('jsonwebtoken');
const uuidv7 = require('uuid').v7;
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const User = require('./models/user');
const user = require('./models/user');
const PORT = 3000;

app.use(cors());
app.use(helmet());
app.use(express.json());

async function connectDB() {
	try {
		await connect(process.env.MONGODB_URI);
		console.log('✅ Connected to MongoDB');
	} catch (error) {
		console.error('❌ MongoDB connection error:', error);
		process.exit(1);
	}
}

app.post('/signup', async (req, res) => {
	const { name, email, phone, password } = req.body;
	console.log('📥 Signup request received:', { name, email, phone });

	const user = await User.create({ _id: uuidv7(), name, email, phone, password });
	user.password = undefined;
	console.log('✅ User created successfully:', user);

	// jwt token generation can be added here
	const jwtToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET);

	return res.status(201).json({
		success: true,
		message: 'User created successfully',
		user,
		token: jwtToken,
	});
});

app.post('/signin', async (req, res) => {
	const { email, password } = req.body;
	console.log('📥 Login request received:', { email });

	const user = await User.findOne({ email });
	if (!user) {
		return res.status(404).json({ success: false, message: 'User not found' });
	}

	if (user.password !== password) {
		return res.status(401).json({ success: false, message: 'Invalid password' });
	}

	// jwt token generation can be added here
	user.password = undefined;
	const jwtToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET);
	return res.status(200).json({
		success: true,
		message: 'Login successful',
		user,
		token: jwtToken,
	});
});

async function authenticateToken(req, res, next) {
	const authHeader = req.headers.authorization;
	if (!authHeader) {
		return res
			.status(401)
			.json({ success: false, message: 'Authorization header missing' });
	}
	const token = authHeader.split(' ')[1];
	try {
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user = await User.findById(decoded.id).select('-password');
		if (!user) {
			return res.status(404).json({ success: false, message: 'User not found' });
		}
		req.user = user;
		next();
	} catch (error) {
		return res.status(401).json({ success: false, message: 'Invalid token' });
	}
}

app.get('/profile', authenticateToken, async (req, res) => {
	req.user.password = undefined;
	return res.status(200).json({
		success: true,
		message: 'User profile fetched successfully',
		user: req.user,
	});
});

app.post('/contacts', authenticateToken, async (req, res) => {
	const { name, email, phone, relationship } = req.body;
	console.log('📥 Add contact request received:', { name, email, phone, relationship });

	req.user.trustedContacts.push({ name, email, phone, relationship });
	await req.user.save();
	console.log('✅ Contact added successfully:', { name, email, phone, relationship });

	req.user.password = undefined;
	return res.status(201).json({
		success: true,
		message: 'Contact added successfully',
		user: req.user,
	});
});

app.listen(PORT, async () => {
	await connectDB();
	console.log(`Server is running on http://localhost:${PORT}`);
});
