#import "Globals.h"

@class SeaDocument;

/*!
	@protocol	AbstractExporter
	@abstract	Acts as a base class for all exporters.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@protocol AbstractExporter <NSObject>

/*!
	@property	hasOptions
	@discussion	Returns whether or not the exporter offers additional options.
	@result		Returns \c YES if the exporter offers additional options through
				the \c showOptions: method, \c NO otherwise.  The implementation in
				this class always returns \c NO.
*/
@property (readonly) BOOL hasOptions;

/*!
	@method		showOptions:
	@discussion	If hasOptions returns YES, this method displays a panel allowing
				the user to configure additional options for the exporter.
	@param		sender
				Ignored.
*/
- (IBAction)showOptions:(id)sender;

/*!
	@property	title
	@discussion	Returns the title of the exporter (as will be displayed in the
				save panel). This must be equal to the \c CFBundleTypeName in the
				\c CFBundleDocumentTypes array.
	@result		Returns an \c NSString representing the title of the exporter.
*/
@property (readonly, copy) NSString *title;

/*!
	@property	extension
	@discussion	Returns the FIRST extension of the file format associated with this
				exporter.
	@result		Returns an \c NSString representing the extension of the file format
				associated with this exporter.
*/
@property (readonly, copy) NSString *extension;

/*!
	@property	fileType
	@discussion	Returns the Uniform Type Identifier (UTI) of the file format associated with this
				exporter.
	@result		Returns an \c NSString representing the UTI of the file format
				associated with this exporter.
 */
@property (readonly, copy) NSString *fileType;

/*!
	@method		optionsString
	@discussion	Returns a brief statement summarizing the current options.
	@result		Returns an \c NSString summarizing the current options.
*/
- (NSString *)optionsString;

/*!
	@method		writeDocument:toFile:
	@discussion	Writes the given document to disk using the format of the
				exporter.
	@param		document
				The document to write to disk.
	@param		path
				The path at which to write the document.
	@result		Returns \c YES if the operation was successful, \c NO otherwise.
*/
- (BOOL)writeDocument:(SeaDocument*)document toFile:(NSString *)path;

@end
