const { Schema, model } = require('mongoose');

const trustedContactSchema = new Schema(
	{
		name: { type: String },
		phone: { type: String },
		email: { type: String },
		relationship: { type: String },
	},
	{ _id: false },
);

const userSchema = new Schema(
	{
		_id: { type: String },
		name: { type: String, required: true },
		email: { type: String, required: true, unique: true },
		phone: { type: String, required: true },
		password: { type: String, required: true },
		trustedContacts: [trustedContactSchema],
	},
	{ timestamps: true },
);

module.exports = model('User', userSchema);
