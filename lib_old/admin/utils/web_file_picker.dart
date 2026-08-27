import 'dart:html' as html;

/// Web-specific file picker using native HTML file input
/// This avoids the file_picker_error that occurs with FilePicker package on web
class WebFilePicker {
  /// Pick a file and return base64 data with filename
  static void pickFile({
    String accept = 'image/*,.svga,.json,.gif',
    required Function(String base64, String fileName) onPicked,
    Function(String)? onError,
  }) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = accept;
      uploadInput.style.display = 'none';
      
      html.document.body?.append(uploadInput);
      
      uploadInput.click();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            if (reader.result != null) {
              onPicked(reader.result as String, file.name);
            }
          });
          reader.onError.listen((e) {
            onError?.call('Failed to read file: ${e.toString()}');
          });
        }
        uploadInput.remove();
      });
      
      uploadInput.onError.listen((e) {
        onError?.call('File picker error: ${e.toString()}');
        uploadInput.remove();
      });
    } catch (e) {
      onError?.call('Failed to open file picker: ${e.toString()}');
    }
  }
  
  /// Pick multiple files
  static void pickMultipleFiles({
    String accept = 'image/*,.svga,.json,.gif',
    required Function(List<String> base64List, List<String> fileNames) onPicked,
    Function(String)? onError,
  }) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = accept;
      uploadInput.multiple = true;
      uploadInput.style.display = 'none';
      
      html.document.body?.append(uploadInput);
      
      uploadInput.click();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final base64List = <String>[];
          final fileNames = <String>[];
          int completed = 0;
          
          for (int i = 0; i < files.length; i++) {
            final file = files[i];
            final reader = html.FileReader();
            reader.readAsDataUrl(file);
            reader.onLoadEnd.listen((e) {
              if (reader.result != null) {
                base64List.add(reader.result as String);
                fileNames.add(file.name);
              }
              completed++;
              if (completed == files.length) {
                onPicked(base64List, fileNames);
              }
            });
            reader.onError.listen((e) {
              onError?.call('Failed to read file ${file.name}: ${e.toString()}');
            });
          }
        }
        uploadInput.remove();
      });
      
      uploadInput.onError.listen((e) {
        onError?.call('File picker error: ${e.toString()}');
        uploadInput.remove();
      });
    } catch (e) {
      onError?.call('Failed to open file picker: ${e.toString()}');
    }
  }
}