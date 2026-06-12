import '../daos/product_dao.dart';
import '../../models/product.dart';

abstract class IProductRepository {
  Future<int> addProduct(Product product);
  Future<List<Product>> getProducts();
  Future<Product?> getProduct(int id);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);
}

class ProductRepository implements IProductRepository {
  final ProductDao _productDao;

  ProductRepository(this._productDao);

  @override
  Future<int> addProduct(Product product) => _productDao.create(product);

  @override
  Future<List<Product>> getProducts() => _productDao.getAll();

  @override
  Future<Product?> getProduct(int id) => _productDao.getById(id);

  @override
  Future<int> updateProduct(Product product) => _productDao.update(product);

  @override
  Future<int> deleteProduct(int id) => _productDao.delete(id);
}
